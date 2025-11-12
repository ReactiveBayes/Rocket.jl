module RocketToArrayOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: to_array()" begin

    println("Testing: operator to_array()")

    run_proxyshowcheck("ToArray", to_array())

    run_testset([
        (
            source = from(1:5) |> to_array(),
            values = @ts([[1, 2, 3, 4, 5], c]),
            source_type = Vector{Int},
        ),
        (
            source = from("Hello, world") |> to_array(),
            values = @ts([['H', 'e', 'l', 'l', 'o', ',', ' ', 'w', 'o', 'r', 'l', 'd'], c]),
            source_type = Vector{Char},
        ),
        (
            source = of('a') |> to_array(),
            values = @ts([['a'], c]),
            source_type = Vector{Char},
        ),
        (source = completed() |> to_array(), values = @ts([[], c])),
        (source = faulted(1) |> to_array(), values = @ts(e(1))),
        (source = never() |> to_array(), values = @ts()),
    ])

end

end
