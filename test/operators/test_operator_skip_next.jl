module RocketSkipNextOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: skip_next()" begin

    run_testset([
        (
            source = from(1:5) |> skip_next(),
            values = @ts(c)
        ),
        (
            source = completed() |> skip_next(),
            values = @ts(c)
        ),
        (
            source = throwError(1) |> skip_next(),
            values = @ts(e(1))
        ),
        (
            source = never() |> skip_next(),
            values = @ts()
        )
    ])

end

end
