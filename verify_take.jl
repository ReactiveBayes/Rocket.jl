using Rocket
using Printf
import Rocket: on_subscribe!, on_unsubscribe!, as_teardown

mutable struct ProbeSource <: Subscribable{Int}
    active::Base.RefValue{Int}
    mode::Symbol
end
ProbeSource(mode) = ProbeSource(Ref(0), mode)
struct ProbeSub <: Teardown
    active::Base.RefValue{Int}
end
as_teardown(::Type{<:ProbeSub}) = Rocket.UnsubscribableTeardownLogic()
on_unsubscribe!(sub::ProbeSub) = (sub.active[] -= 1; nothing)
function on_subscribe!(s::ProbeSource, actor)
    s.active[] += 1
    if s.mode === :next_complete
        next!(actor, 1); complete!(actor)
    elseif s.mode === :next
        next!(actor, 1)
    end
    return ProbeSub(s.active)
end

println("take() hardening checks (all 'active' values should be exactly 0):\n")

# 1. Synchronous replay + complete during subscribe (the reported leak)
let s = ProbeSource(:next_complete)
    subscribe!(s |> take(1), void(Int))
    @printf("  sync complete, no consumer unsubscribe        active=%d\n", s.active[])
end

# 2. Synchronous replay, then consumer ALSO unsubscribes the handle (double)
let s = ProbeSource(:next_complete)
    sub = subscribe!(s |> take(1), void(Int))
    unsubscribe!(sub)           # must NOT double-dispose the upstream
    @printf("  sync complete + consumer unsubscribe (x1)     active=%d\n", s.active[])
    unsubscribe!(sub)           # idempotent: unsubscribing twice is a no-op
    @printf("  sync complete + consumer unsubscribe (x2)     active=%d\n", s.active[])
end

# 3. Live source, take(1) completes after first value, source stays open
let s = ProbeSource(:next)
    sub = subscribe!(s |> take(1), void(Int))
    @printf("  live source, take(1) completed               active=%d\n", s.active[])
    unsubscribe!(sub)           # consumer unsubscribe after completion
    @printf("  live source + consumer unsubscribe            active=%d\n", s.active[])
end

# 4. Consumer unsubscribes BEFORE any emission (source open, mode :none)
let s = ProbeSource(:none)
    sub = subscribe!(s |> take(5), void(Int))
    @printf("  open source, before completion                active=%d\n", s.active[])
    unsubscribe!(sub)
    @printf("  open source, after consumer unsubscribe       active=%d\n", s.active[])
    unsubscribe!(sub)           # double
    @printf("  open source, double consumer unsubscribe      active=%d\n", s.active[])
end
