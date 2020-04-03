module RocketRerunOperatorTest

using Test
using Rocket

include("./test_helpers.jl")

@testset "operator: rerun()" begin

    run_testset([
        (
            source = from(1:5) |> safe() |> map(Int, (d) -> d == 4 ? throw(4) : d) |> rerun(3),
            values = @ts([ 1:3, 1:3, 1:3, 1:3, e(4) ])
        ),
        (
            source = from(1:5) |> safe() |> map(Int, (d) -> d == 4 ? throw(4) : d) |> rerun(3) |> take(6),
            values = @ts([ 1:3, 1:3, c ])
        ),
        (
            source = timer(100, 30) |> safe() |> map(Int, (d) -> d > 2 ? throw("d") : d) |> rerun(1),
            values = @ts(100 ~ [0] ~ 30 ~ [1] ~ 30 ~ [2] ~ 30 ~ [0] ~ 30 ~ [1] ~ 30 ~ [2] ~ e("d"))
        ),
        (
            source = timer(100, 30) |> safe() |> switchMap(Int, (d) -> d > 1 ? throwError("$d", Int) : of(d)) |> rerun(2),
            values = @ts(100 ~ [0] ~ 30 ~ [1] ~ 30 ~ [0] ~ 30 ~ [1] ~ 30 ~ [0] ~ 30 ~ [1] ~ e("2"))
        ),
        (
            source = completed() |> rerun(2),
            values = @ts(c)
        ),
        (
            source = throwError("e") |> rerun(2),
            values = @ts(e("e")),
        ),
        (
            source = never() |> rerun(2),
            values = @ts()
        )
    ])

end

end
