module RocketSkipErrorOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: skip_error()" begin

    println("Testing: operator skip_error()")

    run_proxyshowcheck("SkipError", skip_error())

    run_testset([
        (
            source = from(1:5) |> skip_error(),
            values = @ts([ 1:5, c ])
        ),
        (
            source = completed() |> skip_error(),
            values = @ts(c)
        ),
        (
            source = throwError(1) |> skip_error(),
            values = @ts()
        ),
        (
            source = never() |> skip_error(),
            values = @ts()
        )
    ])

end

end
