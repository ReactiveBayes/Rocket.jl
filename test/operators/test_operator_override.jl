module RocketOverrideOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: override()" begin

    println("Testing: operator override()")

    run_proxyshowcheck("Override", override(OverrideHandler(Int, nothing)))

    global_handler1 = OverrideHandler(Int, nothing)
    global_handler2 = OverrideHandler(Int, nothing)

    run_testset([
        (
            source      = from(1:5) |> override(OverrideHandler(Char, 'a')),
            values      = @ts([ 'a', 'a', 'a', 'a', 'a', c ]),
            source_type = Union{Int, Char}
        ),
        (
            source      = from(1:5) |> tap(i -> Rocket.setvalue!(global_handler1, i ^ 2)) |> override(global_handler1),
            values      = @ts([ 1, 4, 9, 16, 25, c ]),
            source_type = Int
        ),
        (
            source      = from(1:5) |> override(global_handler2) |> tap(i -> Rocket.setvalue!(global_handler2, i)),
            values      = @ts([ 1, 1, 1, 1, 1, c ]),
            source_type = Int
        ),
        (
            source      = completed(Int) |> override(OverrideHandler(Char, 'a')),
            values      = @ts(c),
            source_type = Union{Int, Char}
        ),
        (
            source      = faulted(String, "e") |> override(OverrideHandler(Char, 'a')),
            values      = @ts(e("e")),
            source_type = Union{String, Char}
        ),
        (
            source = never() |> override(OverrideHandler(Char, 'a')),
            values = @ts()
        )
    ])

end

end
