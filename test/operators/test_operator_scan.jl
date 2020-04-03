module RocketScanOperatorTest

using Test
using Rocket

include("./test_helpers.jl")

@testset "operator: scan()" begin

    run_testset([
        (
            source      = from(1:5) |> scan(Int, +, 1),
            values      = @ts([ 2, 4, 7, 11, 16, c ]),
            source_type = Int
        ),
        (
            source      = from(1:5) |> scan(+),
            values      = @ts([ 1, 3, 6, 10, 15, c ]),
            source_type = Int
        ),
        (
            source      = from(1:5) |> scan(Vector{Int}, (d, c) -> [ c..., d ], Int[]),
            values      = @ts([ [1], [1, 2], [1, 2, 3], [1, 2, 3, 4], [1, 2, 3, 4, 5], c ]),
            source_type = Vector{Int}
        ),
        (
            source      = completed(Int) |> scan(+),
            values      = @ts(c),
            source_type = Int
        ),
        (
            source      = completed(Int) |> scan(Int, +, 2),
            values      = @ts(c),
            source_type = Int
        ),
        (
            source      = throwError("e") |> scan(+),
            values      = @ts(e("e")),
        ),
        (
            source = never() |> scan(+),
            values = @ts()
        )
    ])

end

end
