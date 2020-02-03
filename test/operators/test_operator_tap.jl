module RocketTapOperatorTest

using Test
using Rocket

@testset "operator: tap()" begin

    @testset begin
        values = Int[]
        source = from(1:5) |> tap(d -> push!(values, d))
        actor  = keep(Int)

        @test values == []

        subscribe!(source, actor)

        @test actor.values == [ 1, 2, 3, 4, 5 ]
        @test values       == [ 1, 2, 3, 4, 5 ]

        subscribe!(source, actor)

        @test actor.values == [ 1, 2, 3, 4, 5, 1, 2, 3, 4, 5 ]
        @test values       == [ 1, 2, 3, 4, 5, 1, 2, 3, 4, 5 ]
    end

    @testset begin
        values = Int[]
        source = completed(Int) |> tap(d -> push!(values, d))
        actor  = keep(Int)

        @test values == []

        subscribe!(source, actor)

        @test actor.values == [ ]
        @test values       == [ ]
    end

end

end
