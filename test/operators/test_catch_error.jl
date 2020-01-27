module RxCatchErrorOperatorTest

using Test
using Rx

@testset "catch_error operator" begin

    @testset begin
        source = from(1:5) |> map(Int, (d) -> d == 4 ? error(4) : d) |> catch_error((err, obs) -> from(1:3))
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ 1, 2, 3, 1, 2, 3 ]
    end

    @testset begin
        source = from(1:5) |> map(Int, (d) -> d == 4 ? error(4) : d) |> catch_error((err, obs) -> obs) |> take(10)
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [1, 2, 3, 1, 2, 3, 1, 2, 3, 1]
    end

    @testset begin
        source = from(1:5) |> map(Int, (d) -> d == 4 ? error(4) : d) |> catch_error((err, obs) -> throw("err"))
        actor  = keep(Int)

        @test_throws ErrorException("err") subscribe!(source, actor)
        @test actor.values == [ 1, 2, 3 ]
    end
end

end
