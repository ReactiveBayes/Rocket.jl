module RocketPairwiseOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: pairwise()" begin

    println("Testing: operator pairwise()")

    run_proxyshowcheck("Pairwise", pairwise())

    run_testset([
        (
            source      = from(1:5) |> pairwise(),
            values      = @ts([ (1, 2), (2, 3), (3, 4), (4, 5), c ]),
            source_type = Tuple{Int, Int}
        ),
        (
            source      = of(1) |> pairwise(),
            values      = @ts(c),
            source_type = Tuple{Int, Int}
        ),
        (
            source      = completed() |> pairwise(),
            values      = @ts(c)
        ),
        (
            source      = faulted(Int, "e") |> pairwise(),
            values      = @ts(e("e"))
        ),
        (
            source      = never() |> pairwise(),
            values      = @ts()
        ),
        (
            source      = from(1:5) |> pairwise(0),
            values      = @ts([ (0, 1), (1, 2), (2, 3), (3, 4), (4, 5), c ]),
            source_type = Tuple{Int, Int}
        ),
        (
            source      = from(1:5) |> pairwise(0.0),
            values      = @ts([ (0.0, 1), (1, 2), (2, 3), (3, 4), (4, 5), c ]),
            source_type = Tuple{Union{Int, Float64}, Union{Int, Float64}}
        ),
        (
            source      = from(1:5) |> pairwise("0"),
            values      = @ts([ ("0", 1), (1, 2), (2, 3), (3, 4), (4, 5), c ]),
            source_type = Tuple{Union{Int, String}, Union{Int, String}}
        ),
        (
            source      = of(1) |> pairwise(0),
            values      = @ts([ (0, 1), c ]),
            source_type = Tuple{Int, Int}
        ),
        (
            source      = completed() |> pairwise(0),
            values      = @ts(c)
        ),
        (
            source      = faulted(Int, "e") |> pairwise(0),
            values      = @ts(e("e"))
        ),
        (
            source      = never() |> pairwise(0),
            values      = @ts()
        )
    ])

end

end
