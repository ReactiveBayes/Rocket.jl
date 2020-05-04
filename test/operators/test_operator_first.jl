module RocketFirstOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: first()" begin

    println("Testing: operator first()")

    run_testset([

        (
            source = from(1:42) |> first(),
            values = @ts([ 1, c ])
        ),
        (
            source = timer(50) |> first(),
            values = @ts(50 ~ [ 0, c ])
        ),
        (
            source = completed() |> first(),
            values = @ts(e(FirstNotFoundException()))
        ),
        (
            source      = completed(Int) |> first(default = "String"),
            values      = @ts([ "String", c ]),
            source_type = Union{Int, String}
        ),
        (
            source      = throwError(Int, "e") |> first(),
            values      = @ts(e("e")),
            source_type = Union{Int}
        ),
        (
            source      = throwError(Int, "e") |> first(default = "String"),
            values      = @ts(e("e")),
            source_type = Union{Int, String}
        ),
        (
            source = never() |> first(),
            values = @ts()
        )
    ])

end

end
