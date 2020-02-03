module RocketReduceOperatorTest

using Test
using Rocket

@testset "operator: reduce()" begin

    @testset begin
        source = from(1:5) |> reduce(Int, (d, c) -> c + d)
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ 15 ]
    end

    @testset begin
        source = from(1:5) |> reduce(Vector{Int}, (d, c) -> [ c..., d ], Int[])
        actor  = keep(Vector{Int})

        subscribe!(source, actor)

        @test actor.values == [ [1, 2, 3, 4, 5] ]
    end

    @testset begin
        source = completed() |> reduce(Int, (d, c) -> c + d)
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ ]
    end

    @CreateReduceOperator(Accumulate, Int, Int, (d, c) -> c + d)

    @testset begin
        source = from(1:5) |> AccumulateReduceOperator(0)
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ 15 ]
    end

end

end
