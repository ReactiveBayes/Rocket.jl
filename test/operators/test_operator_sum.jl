module RocketSumOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: sum()" begin

    println("Testing: operator sum()")

    run_proxyshowcheck("Sum", sum())

    run_testset([
        (
            source = from(1:42) |> sum(),
            values = @ts([ 903, c ]),
            source_type = Union{Nothing, Int}
        ),
        (
            source = from(1:42) |> sum(from = 97),
            values = @ts([ 1000, c ]),
            source_type = Union{Nothing, Int}
        ),
        (
            source = completed() |> sum(),
            values = @ts([ nothing, c ])
        ),
        (
            source = throwError(1) |> sum(),
            values = @ts(e(1))
        ),
        (
            source = never() |> sum(),
            values = @ts()
        )
    ])

end

end
