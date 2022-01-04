module RocketCatchErrorOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: catch_error()" begin

    println("Testing: operator catch_error()")

    run_testset([
        (
            source = from(1:5) |> safe() |> map(Int, (d) -> d == 4 ? error(4) : d) |> catch_error((err, obs) -> from(1:3)),
            values = @ts([ 1, 2, 3, 1, 2, 3, c ])
        ),
        (
            source = from(1:5) |> async(0) |> safe() |> map(Int, (d) -> d == 4 ? error(4) : d) |> catch_error((err, obs) -> obs) |> take(10),
            values = @ts([ 1 ] ~ [ 2 ] ~ [ 3 ] ~ [ 1 ] ~ [ 2 ] ~ [ 3 ] ~ [ 1 ] ~ [ 2 ] ~ [ 3 ] ~ [ 1, c ])
        ),
        (
            source = from(1:5) |> switch_map(Int, (d) -> d == 4 ? faulted(Int, 4) : of(d)) |> catch_error((err, obs) -> of(5)),
            values = @ts([ 1, 2, 3, 5, c ])
        ),
        (
            source = from(1:5) |> safe() |> map(Int, (d) -> d == 4 ? error(4) : d) |> catch_error((err, obs) -> completed(Int)),
            values = @ts([ 1, 2, 3, c ])
        ),
        (
            source = from(1:5) |> safe() |> map(Int, (d) -> d == 4 ? error(4) : d) |> catch_error((err, obs) -> never(Int)),
            values = @ts([ 1, 2, 3 ])
        ),
        (
            source = from(1:5) |> safe() |> map(Int, (d) -> d == 4 ? error(4) : d) |> catch_error((err, obs) -> throw("e")),
            values = @ts([ 1, 2, 3, e("e") ])
        )
    ])
end

end
