module RocketFindIndexOperatorTest

using Test
using Rocket

@testset "operator: find_index()" begin

    @testset begin
        source = from(0:5) |> find_index(d -> d !== 0 && d % 2 == 0)
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ 3 ]
    end

    @testset begin
        source = completed(Int) |> find_index(d -> d % 2 == 0)
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ ]
    end

end

end
