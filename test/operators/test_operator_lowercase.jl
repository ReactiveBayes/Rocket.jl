module RocketLowercaseOperatorTest

using Test
using Rocket

include("./test_helpers.jl")

@testset "operator: lowercase()" begin

    run_testset([
        (
            source = from("Hello, world") |> lowercase(),
            values = @ts(['h', 'e', 'l', 'l', 'o', ',', ' ', 'w', 'o', 'r', 'l', 'd'] ~ c)
        ),
        (
            source = completed() |> lowercase(),
            values = @ts(c)
        ),
        (
            source      = throwError("e", String) |> lowercase(),
            values      = @ts(e("e")),
            source_type = String
        ),
        (
            source = never() |> lowercase(),
            values = @ts()
        )
    ])

end

end
