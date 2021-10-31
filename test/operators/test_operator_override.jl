module RocketOverrideOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: override()" begin

    println("Testing: operator override()")

    run_proxyshowcheck("Override", override(OverrideHandler(Int)))

    global_handler1 = OverrideHandler(Int)
    global_handler2 = OverrideHandler(Int)

    run_testset([
        (
            source      = from(1:5) |> override(OverrideHandler('a')),
            values      = @ts([ 'a', 'a', 'a', 'a', 'a', c ]),
            source_type = Union{Int, Char}
        ),
        (
            source      = from(1:5) |> tap(i -> Rocket.setvalue!(global_handler1, i ^ 2)) |> override(global_handler1),
            values      = @ts([ 1, 4, 9, 16, 25, c ]),
            source_type = Int
        ),
        (
            source      = from(1:5) |> override(global_handler2) |> tap(i -> Rocket.setvalue!(global_handler2, 3)),
            values      = @ts([ 1, 3, 3, 3, 3, c ]),
            source_type = Int
        ),
        (
            source      = completed(Int) |> override(OverrideHandler('a')),
            values      = @ts(c),
            source_type = Union{Int, Char}
        ),
        (
            source      = faulted(String, "e") |> override(OverrideHandler('a')),
            values      = @ts(e("e")),
            source_type = Union{String, Char}
        ),
        (
            source = never() |> override(OverrideHandler('a')),
            values = @ts()
        )
    ])

end

end
