module RocketTapOnUnsubscribeOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: tap_on_unsubscribe()" begin

    println("Testing: operator tap_on_unsubscribe()")

    run_proxyshowcheck(
        "TapOnUnsubscribe",
        tap_on_unsubscribe(() -> begin end),
        args = (check_subscription = true,),
    )

    @testset begin
        values = Int[]
        source = from(1:5) |> tap_on_unsubscribe(() -> push!(values, -1))
        actor = keep(Int)

        @test values == []

        subscription = subscribe!(source, actor)

        @test actor.values == [1, 2, 3, 4, 5]
        @test values == []

        unsubscribe!(subscription)
        @test values == [-1]
        unsubscribe!(subscription)
        @test values == [-1]

        subscription = subscribe!(source, actor)

        @test actor.values == [1, 2, 3, 4, 5, 1, 2, 3, 4, 5]
        @test values == [-1]

        unsubscribe!(subscription)
        @test values == [-1, -1]
        unsubscribe!(subscription)
        @test values == [-1, -1]
    end

    struct DummySource <: Subscribable{Any}
        values::Vector{Any}
    end

    function Rocket.on_subscribe!(source::DummySource, actor)
        next!(actor, 1)
        return DummySubscription(source.values)
    end

    struct DummySubscription <: Teardown
        values::Vector{Any}
    end

    Rocket.as_teardown(::Type{<: DummySubscription}) = UnsubscribableTeardownLogic()

    function Rocket.on_unsubscribe!(subscription::DummySubscription)
        push!(subscription.values, 0)
        return nothing
    end

    @testset begin
        values = []
        source =
            DummySource(values) |>
            tap_on_unsubscribe(() -> push!(values, -1), TapBeforeUnsubscription())

        @test values == []

        subscription = subscribe!(source, (e) -> push!(values, e))

        @test values == [1]

        unsubscribe!(subscription)

        @test values == [1, -1, 0]

        unsubscribe!(subscription)

        @test values == [1, -1, 0, 0]

        subscription = subscribe!(source, (e) -> push!(values, e))

        @test values == [1, -1, 0, 0, 1]

        unsubscribe!(subscription)

        @test values == [1, -1, 0, 0, 1, -1, 0]

        unsubscribe!(subscription)

        @test values == [1, -1, 0, 0, 1, -1, 0, 0]
    end

    @testset begin
        values = []
        source =
            DummySource(values) |>
            tap_on_unsubscribe(() -> push!(values, -1), TapAfterUnsubscription())

        @test values == []

        subscription = subscribe!(source, (e) -> push!(values, e))

        @test values == [1]

        unsubscribe!(subscription)

        @test values == [1, 0, -1]

        unsubscribe!(subscription)

        @test values == [1, 0, -1, 0]

        subscription = subscribe!(source, (e) -> push!(values, e))

        @test values == [1, 0, -1, 0, 1]

        unsubscribe!(subscription)

        @test values == [1, 0, -1, 0, 1, 0, -1]

        unsubscribe!(subscription)

        @test values == [1, 0, -1, 0, 1, 0, -1, 0]
    end

    @testset begin
        values = Int[]
        source = completed(Int) |> tap_on_unsubscribe(() -> push!(values, -1))
        actor = keep(Int)

        @test values == []

        subscription = subscribe!(source, actor)

        @test actor.values == []
        @test values == []

        unsubscribe!(subscription)

        @test actor.values == []
        @test values == [-1]

        unsubscribe!(subscription)

        @test actor.values == []
        @test values == [-1]
    end

end

end
