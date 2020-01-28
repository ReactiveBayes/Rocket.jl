module RxMinOperatorTest

using Test
using Rx

@testset "operator: min()" begin

    @testset begin
        source = from(1:42) |> min()
        actor  = keep(Union{Int, Nothing})

        subscribe!(source, actor)

        @test actor.values == [ 1 ]
    end

    @testset begin
        source = completed(Int) |> min()
        actor  = keep(Union{Int, Nothing})

        subscribe!(source, actor)

        @test actor.values == [ nothing ]
    end

    @testset begin
        source = from(1:5) |> min(from = -100)
        actor  = keep(Union{Int, Nothing})

        subscribe!(source, actor)

        @test actor.values == [ -100 ]
    end

end

end
