module RocketMaxOperatorTest

using Test
using Rocket

@testset "operator: max()" begin

    @testset begin
        source = from(1:42) |> max()
        actor  = keep(Union{Int, Nothing})

        subscribe!(source, actor)

        @test actor.values == [ 42 ]
    end

    @testset begin
        source = completed(Int) |> min()
        actor  = keep(Union{Int, Nothing})

        subscribe!(source, actor)

        @test actor.values == [ nothing ]
    end

    @testset begin
        source = from(1:5) |> max(from = 100)
        actor  = keep(Union{Int, Nothing})

        subscribe!(source, actor)

        @test actor.values == [ 100 ]
    end

end

end
