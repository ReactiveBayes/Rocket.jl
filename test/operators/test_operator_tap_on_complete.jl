module RocketTapOnCompleteOperatorTest

using Test
using Rocket

@testset "operator: tap_on_complete()" begin

    @testset begin
        values = Int[]
        source = from(1:5) |> tap_on_complete(() -> push!(values, -1))
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
        source = throwError(Int) |> tap_on_complete(() -> push!(values, -1))
        actor  = keep(Int)

        @test values == []

        try
            subscribe!(source, actor)
        catch _
        end

        @test actor.values == [ ]
        @test values       == [ ]
    end

    @testset begin
        values = Int[]
        source = completed(Int) |> tap_on_complete(() -> push!(values, -1))
        actor  = keep(Int)

        @test values == []

        subscribe!(source, actor)

        @test actor.values == [ ]
        @test values       == [ -1 ]
    end

end

end
