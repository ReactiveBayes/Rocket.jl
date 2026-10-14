using Rocket
using Printf
import Rocket: on_subscribe!, on_unsubscribe!, as_teardown

# A source that counts currently-live subscriptions (subscribed but not yet
# unsubscribed). On subscribe it can synchronously emit a value and complete,
# which is exactly the condition that triggers the take() leak.
mutable struct ProbeSource <: Subscribable{Int}
    active::Base.RefValue{Int}
    mode::Symbol   # :next_complete, :complete, :error, :next (stay open)
end
ProbeSource(mode) = ProbeSource(Ref(0), mode)

struct ProbeSub <: Teardown
    active::Base.RefValue{Int}
end
as_teardown(::Type{<:ProbeSub}) = Rocket.UnsubscribableTeardownLogic()
function on_unsubscribe!(sub::ProbeSub)
    sub.active[] -= 1
    return nothing
end

function on_subscribe!(s::ProbeSource, actor)
    s.active[] += 1
    if s.mode === :next_complete
        next!(actor, 1); complete!(actor)
    elseif s.mode === :complete
        complete!(actor)
    elseif s.mode === :error
        next!(actor, 1); error!(actor, "boom")
    elseif s.mode === :next
        next!(actor, 1)   # stays open, no complete
    end
    return ProbeSub(s.active)
end

# Run an operator against a probe source whose stream completes synchronously
# inside subscribe!. A correct operator disposes the upstream subscription as
# part of that completion, so `active` returns to 0. A leak leaves it at 1.
# We deliberately do NOT unsubscribe the returned handle: we are measuring
# whether the operator cleans up the upstream *on its own* at completion.
function probe(name, mode, make_pipeline)
    src = ProbeSource(mode)
    try
        subscribe!(make_pipeline(src), void(Int))
    catch err
        # error-mode pipelines may throw; we still check leaks
    end
    leaked = src.active[]
    @printf("  %-14s mode=%-14s active=%d %s\n", name, mode, leaked, leaked == 0 ? "ok" : "  <-- LEAK")
end

println("Leaked = main-source subscriptions still live after the pipeline completed/was disposed (expect 0)\n")

probe("take(1)",      :next_complete, s -> s |> take(1))
probe("take(1)",      :next,          s -> s |> take(1))  # severe case: source stays open
probe("switch_map",   :next_complete, s -> s |> switch_map(Int, d -> of(d)))
probe("merge_map",    :next_complete, s -> s |> merge_map(Int, d -> of(d)))
probe("concat_map",   :next_complete, s -> s |> concat_map(Int, d -> of(d)))
probe("exhaust_map",  :next_complete, s -> s |> exhaust_map(Int, d -> of(d)))
probe("error_if",     :next,          s -> s |> error_if(d -> true, d -> "x"))  # errors synchronously on first value
probe("safe",         :next_complete, s -> s |> safe())
probe("take_until",   :next_complete, s -> s |> take_until(never()))
probe("with_latest",  :next_complete, s -> s |> with_latest(of(9)))
