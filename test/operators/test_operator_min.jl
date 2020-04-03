module RocketMinOperatorTest

using Test
using Rocket

include("./test_helpers.jl")

@testset "operator: min()" begin

    run_testset([
        (
            source      = from(1:42) |> min(),
            values      = @ts([ 1, c ]),
            source_type = Union{Int, Nothing}
        ),
        (
            source      = from(1:42) |> min(from = -100),
            values      = @ts([ -100, c ]),
            source_type = Union{Int, Nothing}
        ),
        (
            source      = from(1:42) |> min() |> some(),
            values      = @ts([ 1, c ]),
            source_type = Int
        ),
        (
            source      = completed(Int) |> min(),
            values      = @ts([ nothing, c ]),
            source_type = Union{Int, Nothing}
        ),
        (
            source      = throwError("e", String) |> min(),
            values      = @ts(e("e")),
            source_type = Union{Nothing, String}
        ),
        (
            source = never() |> min(),
            values = @ts()
        )
    ])

end

end
