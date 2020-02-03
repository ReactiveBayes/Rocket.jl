module RocketEnumerateOperatorTest

using Test
using Rocket

@testset "operator: enumerate()" begin

    @testset begin
        source = from([ 3, 2, 1 ]) |> enumerate()
        actor  = keep(Tuple{Int, Int})

        subscribe!(source, actor)

        @test actor.values == [(3, 1), (2, 2), (1, 3)]
    end

    @testset begin
        source = completed(Int) |> enumerate()
        actor  = keep(Tuple{Int, Int})

        subscribe!(source, actor)

        @test actor.values == [ ]
    end

end

end
