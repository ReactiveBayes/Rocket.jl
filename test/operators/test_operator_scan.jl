module RocketScanOperatorTest

using Test
using Rocket

@testset "operator: scan()" begin

    @testset begin
        source = from(1:5) |> scan(Int, (d, c) -> c + d)
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [1, 3, 6, 10, 15]
    end

    @testset begin
        source = from(1:5) |> scan(Vector{Int}, (d, c) -> [ c..., d ], Int[])
        actor  = keep(Vector{Int})

        subscribe!(source, actor)

        @test actor.values == [[1], [1, 2], [1, 2, 3], [1, 2, 3, 4], [1, 2, 3, 4, 5]]
    end

    @testset begin
        source = completed() |> scan(Int, (d, c) -> c + d)
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ ]
    end

    @CreateScanOperator(Accumulate, Int, Int, (d, c) -> c + d)

    @testset begin
        source = from(1:5) |> AccumulateScanOperator(0)
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [1, 3, 6, 10, 15]
    end

end

end
