module RocketFindOperatorTest

using Test
using Rocket

@testset "operator: find()" begin

    @testset begin
        source = from(1:5) |> find(d -> d % 2 == 0)
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ 2 ]
    end

    @testset begin
        source = completed(Int) |> find(d -> d % 2 == 0)
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ ]
    end

end

end
