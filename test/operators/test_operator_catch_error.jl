module RxCatchErrorOperatorTest

using Test
using Rx

@testset "catch_error()" begin

    @testset begin
        source = from(1:5) |> safe() |> map(Int, (d) -> d == 4 ? error(4) : d) |> catch_error((err, obs) -> from(1:3))
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ 1, 2, 3, 1, 2, 3 ]
    end

    @testset begin
        source = from(1:5) |> safe() |> map(Int, (d) -> d == 4 ? error(4) : d) |> catch_error((err, obs) -> obs) |> take(10)
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [1, 2, 3, 1, 2, 3, 1, 2, 3, 1]
    end

    @testset begin
        source = from(1:5) |> safe() |> map(Int, (d) -> d == 4 ? error(4) : d) |> catch_error((err, obs) -> error("err"))
        actor  = keep(Int)

        @test_throws ErrorException("err") subscribe!(source, actor)
        @test actor.values == [ 1, 2, 3 ]
    end

    @testset begin
        source = from(1:5) |> switchMap(Int, (d) -> d == 4 ? throwError(4, Int) : of(d)) |> catch_error((err, obs) -> of(5))
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ 1, 2, 3, 5 ]
    end
end

end
