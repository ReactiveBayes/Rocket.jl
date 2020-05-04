module RocketMaxOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: max()" begin

    println("Testing: operator max()")

    run_proxyshowcheck("Max", max())

    run_testset([
        (
            source      = from(1:42) |> max(),
            values      = @ts([ 42, c ]),
            source_type = Union{Int, Nothing}
        ),
        (
            source      = from(1:42) |> max(from = 100),
            values      = @ts([ 100, c ]),
            source_type = Union{Int, Nothing}
        ),
        (
            source      = from(1:42) |> max() |> some(),
            values      = @ts([ 42, c ]),
            source_type = Int
        ),
        (
            source      = completed(Int) |> max(),
            values      = @ts([ nothing, c ]),
            source_type = Union{Int, Nothing}
        ),
        (
            source      = throwError(String, "e") |> max(),
            values      = @ts(e("e")),
            source_type = Union{Nothing, String}
        ),
        (
            source = never() |> max(),
            values = @ts()
        )
    ])

end

end
