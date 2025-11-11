module RocketFindOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: find()" begin

    println("Testing: operator find()")

    run_testset([
        (
            source = from(0:5) |> find(d -> d !== 0 && d % 2 == 0),
            values = @ts([2, c]),
            source_type = Int,
        ),
        (
            source = of(1) |> find(d -> d !== 0 && d % 2 == 0),
            values = @ts(c),
            source_type = Int,
        ),
        (
            source = of("Something") |> find(d -> true),
            values = @ts(["Something", c]),
            source_type = String,
        ),
        (source = completed() |> find(d -> d !== 0 && d % 2 == 0), values = @ts(c)),
        (source = completed() |> find(d -> true), values = @ts(c)),
        (source = never() |> find(d -> true), values = @ts()),
    ])

end

end
