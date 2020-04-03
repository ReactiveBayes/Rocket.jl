module RocketUppercaseOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: uppercase()" begin

    run_testset([
        (
            source = from("Hello, world") |> uppercase(),
            values = @ts(['H', 'E', 'L', 'L', 'O', ',', ' ', 'W', 'O', 'R', 'L', 'D', c])
        ),
        (
            source = completed() |> uppercase(),
            values = @ts(c)
        ),
        (
            source      = throwError("e", String) |> uppercase(),
            values      = @ts(e("e")),
            source_type = String
        ),
        (
            source = never() |> uppercase(),
            values = @ts()
        )
    ])

end

end
