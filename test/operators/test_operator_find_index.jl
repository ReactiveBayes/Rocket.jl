module RocketFindIndexOperatorTest

using Test
using Rocket

include("./test_helpers.jl")

@testset "operator: find_index()" begin

    run_testset([
        (
            source      = from(0:5) |> find_index(d -> d !== 0 && d % 2 == 0),
            values      = @ts([ 3, c ]),
            source_type = Int
        ),
        (
            source      = of(1) |> find_index(d -> d !== 0 && d % 2 == 0),
            values      = @ts(c),
            source_type = Int
        ),
        (
            source      = of("Something") |> find_index(d -> true),
            values      = @ts([ 1, c ]),
            source_type = Int
        ),
        (
            source      = completed() |> find_index(d -> d !== 0 && d % 2 == 0),
            values      = @ts(c)
        ),
        (
            source      = completed() |> find_index(d -> true),
            values      = @ts(c)
        ),
        (
            source      = never() |> find_index(d -> true),
            values      = @ts()
        )
    ])

end

end
