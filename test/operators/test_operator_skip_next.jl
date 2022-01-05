module RocketSkipNextOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: skip_next()" begin

    println("Testing: operator skip_next()")

    run_testset([
        (
            source = from_iterable(1:5) |> skip_next(),
            values = @ts(c)
        ),
        (
            source = completed() |> skip_next(),
            values = @ts(c)
        ),
        (
            source = faulted(1) |> skip_next(),
            values = @ts(e(1))
        ),
        (
            source = never() |> skip_next(),
            values = @ts()
        )
    ])

end

end
