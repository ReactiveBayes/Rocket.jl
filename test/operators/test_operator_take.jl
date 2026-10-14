module RocketTakeOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: take()" begin

    println("Testing: operator take()")

    run_proxyshowcheck("Take", take(1), args = (check_subscription = true,))

    run_testset([
        (source = from(1:5) |> take(3), values = @ts([1:3, c])),
        (source = from(1:5) |> take(0), values = @ts(c)),
        (source = from(1:5) |> async(0) |> take(3), values = @ts([1] ~ [2] ~ [3, c])),
        (
            source = timer(100, 30) |> take(3),
            values = @ts(100 ~ [0] ~ 30 ~ [1] ~ 30 ~ [2, c])
        ),
        (source = completed() |> take(10), values = @ts(c)),
        (source = faulted("e") |> take(10), values = @ts(e("e"))),
        (source = never() |> take(10), values = @ts()),
    ])

    @testset "Infinite reaction" begin
        source = Subject(Int)
        events = []

        subscription = subscribe!(
            source |> take(3),
            lambda(
                on_next = (state) -> begin
                    push!(events, state)
                    next!(source, state + 1)
                end,
                on_complete = () -> push!(events, "c"),
            ),
        )

        next!(source, 1)

        @test events == [1, 2, 3, "c"]
    end

    @testset "Synchronous completion disposes the upstream subscription" begin
        # When the source emits synchronously during `subscribe!` (e.g. a
        # replaying subject), `take(n)` can complete before its subscription is
        # stored. The subscription must still be disposed so that the upstream
        # is not kept alive after completion. Reported in
        # https://github.com/ReactiveBayes/RxInfer.jl/issues/704
        for make_source in (() -> RecentSubject(Int), () -> ReplaySubject(Int, 1))
            source = make_source()
            next!(source, 1)                       # prime: replay on subscribe

            upstream_evaluations = Ref(0)
            upstream = source |> map(Int, v -> (upstream_evaluations[] += 1; v))

            # Each `take(1)` replays the primed value synchronously and completes
            # immediately inside `subscribe!`.
            for _ in 1:10
                subscribe!(upstream |> take(1), void(Int))
            end

            # All 10 take(1) subscriptions should have been disposed, so a new
            # emission must not re-trigger the upstream `map` for any of them.
            upstream_evaluations[] = 0
            next!(source, 2)
            @test upstream_evaluations[] == 0
        end
    end

    @testset "Upstream is disposed exactly once / unsubscribe is idempotent" begin
        # The upstream subscription must be torn down once and only once,
        # whether `take` completes on its own, the consumer unsubscribes, or
        # both happen. Unsubscribing the returned handle more than once must be
        # a harmless no-op, and no value may reach the actor after disposal.

        # (1) Synchronously-completing source, then consumer unsubscribes twice.
        src = RecentSubject(Int)
        next!(src, 1)                          # primed: replays on subscribe
        upstream_evaluations = Ref(0)
        upstream = src |> map(Int, v -> (upstream_evaluations[] += 1; v))
        sub = subscribe!(upstream |> take(1), void(Int))
        unsubscribe!(sub)
        @test (unsubscribe!(sub); true)        # idempotent: second call must not throw
        upstream_evaluations[] = 0
        next!(src, 2)
        @test upstream_evaluations[] == 0      # fully detached, no re-evaluation

        # (2) Open source, consumer unsubscribes before completion, twice, and a
        #     later emission must be ignored.
        received = Int[]
        src2 = Subject(Int)
        sub2 = subscribe!(src2 |> take(5), lambda(on_next = v -> push!(received, v)))
        next!(src2, 1)
        unsubscribe!(sub2)
        @test (unsubscribe!(sub2); true)       # idempotent
        next!(src2, 2)                         # after unsubscribe: dropped
        @test received == [1]
    end

end

end
