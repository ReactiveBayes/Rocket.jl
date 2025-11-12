module RocketUppercaseOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: uppercase()" begin

    println("Testing: operator uppercase()")

    run_proxyshowcheck("Uppercase", uppercase())

    run_testset([
        (
            source = from("Hello, world") |> uppercase(),
            values = @ts(['H', 'E', 'L', 'L', 'O', ',', ' ', 'W', 'O', 'R', 'L', 'D', c])
        ),
        (source = completed() |> uppercase(), values = @ts(c)),
        (
            source = faulted(String, "e") |> uppercase(),
            values = @ts(e("e")),
            source_type = String,
        ),
        (source = never() |> uppercase(), values = @ts()),
    ])

end

end
