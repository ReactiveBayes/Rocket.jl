module RxFilterOperatorTest

using Test
using Rx

@testset "operator: filter()" begin

    @testset begin
        source = from(1:5) |> filter(d -> d % 2 == 0)
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ 2, 4 ]
    end

    @CreateFilterOperator(Even, Int, d -> d % 2 == 0)

    @testset begin
        source = from(1:5) |> EvenFilterOperator()
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ 2, 4]
    end

    @CreateFilterOperator(Five, d -> d == 5)

    @testset begin
        source = from(1:5) |> FiveFilterOperator{Int}()
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ 5 ]
    end

end

end
