module RocketStartWithOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: start_with()" begin

    println("Testing: operator start_with()")

    run_proxyshowcheck("StartWith", start_with(0))

    run_testset([
        (
            source      = from(1:5) |> start_with(0),
            values      = @ts([ 0, 1, 2, 3, 4, 5, c ]),
            source_type = Int
        ),
        (
            source      = from(1:5) |> start_with(0.0),
            values      = @ts([ 0.0, 1, 2, 3, 4, 5, c ]),
            source_type = Union{Float64, Int}
        ),
        (
            source      = completed(Int) |> start_with("Hello"),
            values      = @ts([ "Hello", c]),
            source_type = Union{String, Int}
        ),
        (
            source = faulted(Int, "e") |> start_with(1),
            values = @ts([ 1, e("e") ]),
            source_type = Int
        ),
        (
            source = never(Int) |> start_with(0),
            values = @ts([ 0 ])
        )
    ])

end

end
