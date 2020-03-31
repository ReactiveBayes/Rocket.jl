module RocketCatchErrorOperatorTest

using Test
using Rocket

@testset "operator: catch_error()" begin

    @testset begin

        testset = [
            (
                source = from(1:5) |> safe() |> map(Int, (d) -> d == 4 ? error(4) : d) |> catch_error((err, obs) -> from(1:3)),
                values = [ 1, 2, 3, 1, 2, 3 ]
            ),
            (
                source = from(1:5) |> safe() |> map(Int, (d) -> d == 4 ? error(4) : d) |> catch_error((err, obs) -> obs) |> take(10),
                values = [ 1, 2, 3, 1, 2, 3 ]
            ),
            (
                source = from(1:5) |> switchMap(Int, (d) -> d == 4 ? throwError(4, Int) : of(d)) |> catch_error((err, obs) -> of(5)),
                values = [ 1, 2, 3, 5 ]
            ),
            (
                source = from(1:5) |> safe() |> map(Int, (d) -> d == 4 ? error(4) : d) |> catch_error((err, obs) -> error("err")),
                values = [ 1, 2, 3 ],
                error  = "err"
            )
        ]

        source = from(1:5) |> safe() |> map(Int, (d) -> d == 4 ? error(4) : d) |> catch_error((err, obs) -> from(1:3))
        actor  = test_actor(Int)

        subscribe!(source, actor)

        @test check_isvalid(actor)
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
