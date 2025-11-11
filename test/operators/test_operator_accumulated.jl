module RocketAccumulatedOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: accumulated()" begin

    println("Testing: operator accumulated()")

    run_proxyshowcheck("Accumulated", accumulated())

    run_testset([
        (
            source = from(1:3) |> accumulated(),
            values = @ts([[1], [1, 2], [1, 2, 3], c]),
            source_type = Vector{Int},
        ),
        (
            source = from(["a", "b", "c"]) |> accumulated(),
            values = @ts([["a"], ["a", "b"], ["a", "b", "c"], c]),
            source_type = Vector{String},
        ),
        (
            source = completed(Int) |> accumulated(),
            values = @ts(c),
            source_type = Vector{Int},
        ),
        (
            source = faulted(Int, "e") |> accumulated(),
            values = @ts(e("e")),
            source_type = Vector{Int},
        ),
        (source = never(Int) |> accumulated(), values = @ts(), source_type = Vector{Int}),
    ])

end

end
