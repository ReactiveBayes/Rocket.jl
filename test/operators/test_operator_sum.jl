module RocketSumOperatorTest

using Test
using Rocket

@testset "operator: sum()" begin

    @testset begin
        source = from(1:42) |> sum()
        actor  = keep(Union{Nothing, Int})

        subscribe!(source, actor)

        @test actor.values == [ 903 ]
    end

    @testset begin
        source = completed(Int) |> sum()
        actor  = keep(Union{Nothing, Int})

        subscribe!(source, actor)

        @test actor.values == [ nothing ]
    end

    @testset begin
        source = from(1:42) |> sum(from = 97)
        actor  = keep(Union{Nothing, Int})

        subscribe!(source, actor)

        @test actor.values == [ 1000 ]
    end

end

end
