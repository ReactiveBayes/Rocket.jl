module RocketFilterOperatorTest

using Test
using Rocket

include("./test_helpers.jl")

@testset "operator: filter()" begin

    run_testset([
        (
            source      = from(1:5) |> filter(d -> d % 2 == 0),
            values      = @ts([ 2, 4 ] ~ c),
            source_type = Int
        ),
        (
            source      = from(1:5) |> filter(d -> d % 2 == 1),
            values      = @ts([ 1, 3, 5 ] ~ c),
            source_type = Int
        ),
        (
            source = completed() |> filter(d -> d % 2 == 1),
            values = @ts(c)
        ),
        (
            source = throwError("e", ) |> filter(d -> d % 2 == 1),
            values = @ts(e("e"))
        ),
        (
            source = never() |> filter(d -> d % 2 == 1),
            values = @ts()
        ),
        (
            source = of(1) |> filter(d -> false),
            values = @ts(c)
        ),
        (
            source = from(1:5) |> filter(d -> true),
            values = @ts([ 1:5 ] ~ c)
        )
    ])

end

end
