module RocketMapToOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: map_to()" begin

    run_testset([
        (
            source      = from(1:5) |> map_to('a'),
            values      = @ts([ 'a', 'a', 'a', 'a', 'a', c ]),
            source_type = Char
        ),
        (
            source = timer(0, 10) |> take(3) |> map_to(1),
            values = @ts([ 1 ] ~ 10 ~ [ 1 ] ~ 10 ~ [ 1, c ])
        ),
        (
            source      = completed() |> map_to(1),
            values      = @ts(c),
            source_type = Int
        ),
        (
            source      = throwError("e", String) |> map_to(1),
            values      = @ts(e("e")),
            source_type = Int
        ),
        (
            source = never() |> map_to(1),
            values = @ts()
        )
    ])

end

end
