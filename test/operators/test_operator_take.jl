module RocketTakeOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: take()" begin

    println("Testing: operator take()")

    run_proxyshowcheck("Take", take(1))

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

end

end
