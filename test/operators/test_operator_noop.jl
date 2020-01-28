module RxNoopOperatorTest

using Test
using Rx

@testset "operator: noop()" begin

    @testset begin
        source = from(1:5)
        actor  = keep(Int)

        for i in 1:1000
            source = source |> map(Int, d -> d + 1) |> noop()
        end

        subscribe!(source, actor)

        @test actor.values == [ 1001, 1002, 1003, 1004, 1005 ]
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
