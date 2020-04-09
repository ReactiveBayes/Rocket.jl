module RocketCountOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: count()" begin

    run_proxyshowcheck("Count", count())

    run_testset([
        (
            source = from(1:42) |> count(),
            values = @ts([ 42, c ])
        ),
        (
            source = from(1:42) |> async() |> count(),
            values = @ts([ 42, c ])
        ),
        (
            source = completed(Int) |> count(),
            values = @ts([ 0, c ])
        ),
        (
            source = never(Int) |> count(),
            values = @ts()
        ),
        (
            source = throwError("e") |> count(),
            values = @ts(e("e"))
        )
    ])

end

end
