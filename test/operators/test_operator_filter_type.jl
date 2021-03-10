module RocketFilterTypeOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: filter_type()" begin

    println("Testing: operator filter_type()")

    run_proxyshowcheck("FilterType", filter_type(Int))

    @test_throws Exception from(1:5) |> filter_type(Float64)

    run_testset([
        (
            source      = from(1:5) |> filter_type(Int),
            values      = @ts([ 1, 2, 3, 4, 5, c ]),
            source_type = Int
        ),
        (
            source      = from(Real[ 1, 2.0, 3, 4.0, 5, 6.0 ]) |> filter_type(Int),
            values      = @ts([ 1, 3, 5, c ]),
            source_type = Int
        ),
        (
            source      = from(Union{Int, Float64}[ 1, 2.0, 3, 4.0, 5, 6.0 ]) |> filter_type(Float64),
            values      = @ts([ 2.0, 4.0, 6.0, c ]),
            source_type = Float64
        ),
        (
            source      = completed() |> filter_type(Int),
            values      = @ts(c),
            source_type = Int
        ),
        (
            source      = faulted("e") |> filter_type(Int),
            values      = @ts(e("e")),
            source_type = Int
        ),
        (
            source      = never() |> filter_type(Int),
            values      = @ts(),
            source_type = Int
        )
    ])

end

end
