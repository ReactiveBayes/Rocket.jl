module RocketReduceOperatorTest

using Test
using Rocket

include("./test_helpers.jl")

@testset "operator: reduce()" begin

    run_testset([
        (
            source      = from(1:5) |> reduce(Int, +, 1),
            values      = @ts([ 16, c ]),
            source_type = Int
        ),
        (
            source      = from(1:5) |> reduce(+),
            values      = @ts([ 15, c ]),
            source_type = Int
        ),
        (
            source      = from(1:5) |> reduce(Vector{Int}, (d, c) -> [ c..., d ], Int[]),
            values      = @ts([ [1, 2, 3, 4, 5], c ]),
            source_type = Vector{Int}
        ),
        (
            source      = completed(Int) |> reduce(+),
            values      = @ts(c),
            source_type = Int
        ),
        (
            source      = completed(Int) |> reduce(Int, +, 2),
            values      = @ts([ 2, c ]),
            source_type = Int
        ),
        (
            source      = throwError("e") |> reduce(+),
            values      = @ts(e("e")),
        ),
        (
            source = never() |> reduce(+),
            values = @ts()
        )
    ])
end

end
