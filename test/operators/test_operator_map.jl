module RocketMapOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: map()" begin

    println("Testing: operator map()")

    # run_proxyshowcheck("Map", map(Any, d -> d))

    run_testset([
        (
            source      = from_iterable(1:5) |> map(OpType(Int), d -> d ^ 2),
            values      = @ts([ 1, 4, 9, 16, 25, c ]),
            source_type = Int
        ),
        (
            source      = from_iterable(1:5) |> map(OpType(Float64), d -> convert(Float64, d)),
            values      = @ts([ 1.0, 2.0, 3.0, 4.0, 5.0, c ]),
            source_type = Float64
        ),
        (
            source      = completed() |> map(OpType(Int), d -> d + 1),
            values      = @ts(c),
            source_type = Int
        ),
        (
            source      = faulted(Int, "e") |> map(OpType(String), d -> string(d)),
            values      = @ts(e("e")),
            source_type = String
        ),
        (
            source      = never() |> map(OpType(Int), d -> 1),
            values      = @ts(),
            source_type = Int
        ),
        (
            source      = from_iterable(1:5) |> map(OpType(Int), d -> 1.0), # Converted to Int
            values      = @ts([ 1, 1, 1, 1, 1, c ]),
            source_type = Int
        ),
        (
            source      = from_iterable(1:5) |> safe() |> map(OpType(Int), d -> 1.0), # Converted to Int
            values      = @ts([ 1, 1, 1, 1, 1, c ]),
            source_type = Int
        )
    ])

end

end
