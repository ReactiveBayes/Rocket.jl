module RocketTapOnSubscribeOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: tap_on_subscribe()" begin

    println("Testing: operator tap_on_subscribe()")

    run_proxyshowcheck("TapOnSubscribe", tap_on_subscribe(() -> begin end))

    @testset begin
        values = Int[]
        source = from(1:5) |> tap_on_subscribe(() -> push!(values, -1))
        actor  = keep(Int)

        @test values == []

        subscribe!(source, actor)

        @test actor.values == [ 1, 2, 3, 4, 5 ]
        @test values       == [ -1 ]

        subscribe!(source, actor)

        @test actor.values == [ 1, 2, 3, 4, 5, 1, 2, 3, 4, 5 ]
        @test values       == [ -1, -1 ]
    end

    @testset begin
        values = Int[]
        source = from(1:5) |> tap_on_subscribe(() -> push!(values, -1), TapBeforeSubscription())

        @test values == []

        subscribe!(source, (e) -> push!(values, e))

        @test values == [ -1, 1, 2, 3, 4, 5 ]

        subscribe!(source, (e) -> push!(values, e))

        @test values == [ -1, 1, 2, 3, 4, 5, -1, 1, 2, 3, 4, 5 ]
    end

    @testset begin
        values = Int[]
        source = from(1:5) |> tap_on_subscribe(() -> push!(values, -1), TapAfterSubscription())

        @test values == []

        subscribe!(source, (e) -> push!(values, e))

        @test values == [ 1, 2, 3, 4, 5, -1 ]

        subscribe!(source, (e) -> push!(values, e))

        @test values == [ 1, 2, 3, 4, 5, -1, 1, 2, 3, 4, 5, -1 ]
    end

    @testset begin
        values = Int[]
        source = completed(Int) |> tap_on_subscribe(() -> push!(values, -1))
        actor  = keep(Int)

        @test values == []

        subscribe!(source, actor)

        @test actor.values == [ ]
        @test values       == [ -1 ]
    end

end

end
