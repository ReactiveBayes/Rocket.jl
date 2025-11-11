module RocketLimitSubscribersOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: limit_subscribers()" begin

    println("Testing: operator limit_subscribers()")

    run_proxyshowcheck(
        "LimitSubscribers",
        limit_subscribers(),
        args = (check_subscription = true,),
    )

    run_testset([
        (source = from(1:5) |> limit_subscribers(), values = @ts([1, 2, 3, 4, 5, c])),
        (source = completed() |> limit_subscribers(), values = @ts(c)),
        (source = faulted(1) |> limit_subscribers(), values = @ts(e(1))),
        (source = never() |> limit_subscribers(), values = @ts()),
    ])

    @testset begin
        values1 = Int[]
        values2 = Int[]
        values3 = Int[]

        guard = LimitSubscribersGuard(1, true)
        subject = Subject(Int)
        source = subject |> limit_subscribers(guard)

        subscription1 = subscribe!(
            source,
            lambda(
                on_next = (d) -> push!(values1, d),
                on_error = (e) -> error(e),
                on_complete = () -> push!(values1, -1),
            ),
        )

        @test values1 == []
        @test values2 == []
        @test values3 == []

        next!(subject, 1)

        @test values1 == [1]
        @test values2 == []
        @test values3 == []

        unsubscribe!(subscription1)

        next!(subject, 1)

        @test values1 == [1]
        @test values2 == []
        @test values3 == []

        subscription1 = subscribe!(
            source,
            lambda(
                on_next = (d) -> push!(values1, d),
                on_error = (e) -> error(e),
                on_complete = () -> push!(values1, -1),
            ),
        )

        next!(subject, 1)

        @test values1 == [1, 1]
        @test values2 == []
        @test values3 == []

        subscription2 = subscribe!(
            source,
            lambda(
                on_next = (d) -> push!(values2, d),
                on_error = (e) -> error(e),
                on_complete = () -> push!(values2, -2),
            ),
        )

        @test values1 == [1, 1, -1]
        @test values2 == []
        @test values3 == []

        next!(subject, 2)

        @test values1 == [1, 1, -1]
        @test values2 == [2]
        @test values3 == []

        unsubscribe!(subscription1)

        @test values1 == [1, 1, -1]
        @test values2 == [2]
        @test values3 == []

        subscription3 = subscribe!(
            source,
            lambda(
                on_next = (d) -> push!(values3, d),
                on_error = (e) -> error(e),
                on_complete = () -> push!(values3, -3),
            ),
        )

        @test values1 == [1, 1, -1]
        @test values2 == [2, -2]
        @test values3 == []

        next!(subject, 3)

        @test values1 == [1, 1, -1]
        @test values2 == [2, -2]
        @test values3 == [3]

        source = subject |> limit_subscribers(guard)

        @test values1 == [1, 1, -1]
        @test values2 == [2, -2]
        @test values3 == [3, -3]

        unsubscribe!(subscription1)
        unsubscribe!(subscription2)
        unsubscribe!(subscription3)

        @test values1 == [1, 1, -1]
        @test values2 == [2, -2]
        @test values3 == [3, -3]
    end

    @testset begin
        values1 = Int[]
        values2 = Int[]
        values3 = Int[]

        guard = LimitSubscribersGuard(2, true)
        subject = Subject(Int)
        source = subject |> limit_subscribers(guard)

        subscription1 = subscribe!(
            source,
            lambda(
                on_next = (d) -> push!(values1, d),
                on_error = (e) -> error(e),
                on_complete = () -> push!(values1, -1),
            ),
        )

        @test values1 == []
        @test values2 == []
        @test values3 == []

        next!(subject, 1)

        @test values1 == [1]
        @test values2 == []
        @test values3 == []

        unsubscribe!(subscription1)

        next!(subject, 1)

        @test values1 == [1]
        @test values2 == []
        @test values3 == []

        subscription1 = subscribe!(
            source,
            lambda(
                on_next = (d) -> push!(values1, d),
                on_error = (e) -> error(e),
                on_complete = () -> push!(values1, -1),
            ),
        )

        next!(subject, 1)

        @test values1 == [1, 1]
        @test values2 == []
        @test values3 == []

        subscription2 = subscribe!(
            source,
            lambda(
                on_next = (d) -> push!(values2, d),
                on_error = (e) -> error(e),
                on_complete = () -> push!(values2, -2),
            ),
        )

        @test values1 == [1, 1]
        @test values2 == []
        @test values3 == []

        next!(subject, 2)

        @test values1 == [1, 1, 2]
        @test values2 == [2]
        @test values3 == []

        unsubscribe!(subscription1)

        @test values1 == [1, 1, 2]
        @test values2 == [2]
        @test values3 == []

        subscription3 = subscribe!(
            source,
            lambda(
                on_next = (d) -> push!(values3, d),
                on_error = (e) -> error(e),
                on_complete = () -> push!(values3, -3),
            ),
        )

        @test values1 == [1, 1, 2]
        @test values2 == [2]
        @test values3 == []

        next!(subject, 3)

        @test values1 == [1, 1, 2]
        @test values2 == [2, 3]
        @test values3 == [3]

        source = subject |> limit_subscribers(guard)

        @test values1 == [1, 1, 2]
        @test values2 == [2, 3, -2]
        @test values3 == [3, -3]

        unsubscribe!(subscription1)
        unsubscribe!(subscription2)
        unsubscribe!(subscription3)

        @test values1 == [1, 1, 2]
        @test values2 == [2, 3, -2]
        @test values3 == [3, -3]
    end

    @testset begin
        values1 = Int[]
        values2 = Int[]
        values3 = Int[]

        guard = LimitSubscribersGuard(1, false)
        subject = Subject(Int)
        source = subject |> limit_subscribers(guard)

        subscription1 = subscribe!(
            source,
            lambda(
                on_next = (d) -> push!(values1, d),
                on_error = (e) -> error(e),
                on_complete = () -> push!(values1, -1),
            ),
        )

        @test values1 == []
        @test values2 == []
        @test values3 == []

        next!(subject, 1)

        @test values1 == [1]
        @test values2 == []
        @test values3 == []

        unsubscribe!(subscription1)

        next!(subject, 1)

        @test values1 == [1]
        @test values2 == []
        @test values3 == []

        subscription1 = subscribe!(
            source,
            lambda(
                on_next = (d) -> push!(values1, d),
                on_error = (e) -> error(e),
                on_complete = () -> push!(values1, -1),
            ),
        )

        next!(subject, 1)

        @test values1 == [1, 1]
        @test values2 == []
        @test values3 == []

        subscription2 = subscribe!(
            source,
            lambda(
                on_next = (d) -> push!(values2, d),
                on_error = (e) -> error(e),
                on_complete = () -> push!(values2, -2),
            ),
        )

        @test values1 == [1, 1, -1]
        @test values2 == []
        @test values3 == []

        next!(subject, 2)

        @test values1 == [1, 1, -1]
        @test values2 == [2]
        @test values3 == []

        unsubscribe!(subscription1)

        @test values1 == [1, 1, -1]
        @test values2 == [2]
        @test values3 == []

        subscription3 = subscribe!(
            source,
            lambda(
                on_next = (d) -> push!(values3, d),
                on_error = (e) -> error(e),
                on_complete = () -> push!(values3, -3),
            ),
        )

        @test values1 == [1, 1, -1]
        @test values2 == [2, -2]
        @test values3 == []

        next!(subject, 3)

        @test values1 == [1, 1, -1]
        @test values2 == [2, -2]
        @test values3 == [3]

        source = subject |> limit_subscribers(guard)

        @test values1 == [1, 1, -1]
        @test values2 == [2, -2]
        @test values3 == [3]

        subscribe!(source, void())

        @test values1 == [1, 1, -1]
        @test values2 == [2, -2]
        @test values3 == [3, -3]

        unsubscribe!(subscription1)
        unsubscribe!(subscription2)
        unsubscribe!(subscription3)

        @test values1 == [1, 1, -1]
        @test values2 == [2, -2]
        @test values3 == [3, -3]
    end

    @testset begin
        values1 = Int[]
        values2 = Int[]
        values3 = Int[]

        guard = LimitSubscribersGuard(2, false)
        subject = Subject(Int)
        source = subject |> limit_subscribers(guard)

        subscription1 = subscribe!(
            source,
            lambda(
                on_next = (d) -> push!(values1, d),
                on_error = (e) -> error(e),
                on_complete = () -> push!(values1, -1),
            ),
        )

        @test values1 == []
        @test values2 == []
        @test values3 == []

        next!(subject, 1)

        @test values1 == [1]
        @test values2 == []
        @test values3 == []

        unsubscribe!(subscription1)

        next!(subject, 1)

        @test values1 == [1]
        @test values2 == []
        @test values3 == []

        subscription1 = subscribe!(
            source,
            lambda(
                on_next = (d) -> push!(values1, d),
                on_error = (e) -> error(e),
                on_complete = () -> push!(values1, -1),
            ),
        )

        next!(subject, 1)

        @test values1 == [1, 1]
        @test values2 == []
        @test values3 == []

        subscription2 = subscribe!(
            source,
            lambda(
                on_next = (d) -> push!(values2, d),
                on_error = (e) -> error(e),
                on_complete = () -> push!(values2, -2),
            ),
        )

        @test values1 == [1, 1]
        @test values2 == []
        @test values3 == []

        next!(subject, 2)

        @test values1 == [1, 1, 2]
        @test values2 == [2]
        @test values3 == []

        unsubscribe!(subscription1)

        @test values1 == [1, 1, 2]
        @test values2 == [2]
        @test values3 == []

        subscription3 = subscribe!(
            source,
            lambda(
                on_next = (d) -> push!(values3, d),
                on_error = (e) -> error(e),
                on_complete = () -> push!(values3, -3),
            ),
        )

        @test values1 == [1, 1, 2]
        @test values2 == [2]
        @test values3 == []

        next!(subject, 3)

        @test values1 == [1, 1, 2]
        @test values2 == [2, 3]
        @test values3 == [3]

        source = subject |> limit_subscribers(guard)

        @test values1 == [1, 1, 2]
        @test values2 == [2, 3]
        @test values3 == [3]

        subscribe!(source, void())

        @test values1 == [1, 1, 2]
        @test values2 == [2, 3, -2]
        @test values3 == [3]

        unsubscribe!(subscription1)
        unsubscribe!(subscription2)
        unsubscribe!(subscription3)

        @test values1 == [1, 1, 2]
        @test values2 == [2, 3, -2]
        @test values3 == [3]
    end

end

end
