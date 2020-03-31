module RocketCatchErrorOperatorTest

using Test
using Rocket

include("./testset.jl")

@testset "operator: catch_error()" begin

    run_testset([
        (
            source = from(1:5) |> safe() |> map(Int, (d) -> d == 4 ? error(4) : d) |> catch_error((err, obs) -> from(1:3)),
            values = [ 1, 2, 3, 1, 2, 3 ]
        ),
        (
            source = from(1:5) |> safe() |> map(Int, (d) -> d == 4 ? error(4) : d) |> catch_error((err, obs) -> obs) |> take(10),
            values = [ 1, 2, 3, 1, 2, 3, 1, 2, 3, 1 ]
        ),
        (
            source = from(1:5) |> switchMap(Int, (d) -> d == 4 ? throwError(4, Int) : of(d)) |> catch_error((err, obs) -> of(5)),
            values = [ 1, 2, 3, 5 ]
        ),
        (
            source = from(1:5) |> safe() |> map(Int, (d) -> d == 4 ? error(4) : d) |> safe() |> catch_error((err, obs) -> completed(Int)),
            values = [ 1, 2, 3 ]
        )
    ])
end

end
