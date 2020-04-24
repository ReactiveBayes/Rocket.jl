module RocketMapOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: map()" begin

    run_proxyshowcheck("Map", map(Any, d -> d))

    run_testset([
        (
            source      = from(1:5) |> map(Int, d -> d ^ 2),
            values      = @ts([ 1, 4, 9, 16, 25, c ]),
            source_type = Int
        ),
        (
            source      = from(1:5) |> map(Float64, d -> convert(Float64, d)),
            values      = @ts([ 1.0, 2.0, 3.0, 4.0, 5.0, c ]),
            source_type = Float64
        ),
        (
            source      = completed() |> map(Int, d -> d + 1),
            values      = @ts(c),
            source_type = Int
        ),
        (
            source      = throwError("e", Int) |> map(String, d -> string(d)),
            values      = @ts(e("e")),
            source_type = String
        ),
        (
            source      = never() |> map(Int, d -> 1),
            values      = @ts(),
            source_type = Int
        ),
        (
            source      = from(1:5) |> map(Int, d -> 1.0), # Invalid output: Float64 instead of Int
            values      = @ts(),
            source_type = Int,
            throws      = Exception
        ),
        (
            source      = from(1:5) |> safe() |> map(Int, d -> 1.0), # Invalid output: Float64 instead of Int
            values      = @ts(e),
            source_type = Int
        )
    ])

end

end
