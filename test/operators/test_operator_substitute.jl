module RocketSubstituteOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: substitute()" begin

    println("Testing: operator substitute()")

    run_proxyshowcheck("Substitute", substitute(Any, identity, SubstituteHandler()), args = (check_subscription = true, ))

    global_handler = SubstituteHandler()

    run_testset([
        (
            source      = from(1:5) |> substitute(Int, identity, SubstituteHandler()),
            values      = @ts([ 1, 1, 1, 1, 1, c ]),
            source_type = Int
        ),
        (
            source      = from(1:5) |> substitute(String, i -> string(i), SubstituteHandler()),
            values      = @ts([ "1", "1", "1", "1", "1", c ]),
            source_type = String
        ),
        (
            source      = completed() |> substitute(String, i -> string(i), SubstituteHandler()),
            values      = @ts(c),
            source_type = String
        ),
        (
            source      = faulted(Int, "e") |> substitute(String, i -> string(i), SubstituteHandler()),
            values      = @ts(e("e")),
            source_type = String
        ),
        (
            source      = never() |> substitute(String, i -> string(i), SubstituteHandler()),
            values      = @ts(),
            source_type = String
        ),
        (
            source      = from(1:5) |> tap(_ -> release!(global_handler)) |> substitute(Int, identity, global_handler),
            values      = @ts([ 1, 1, 2, 3, 5, c ]),
            source_type = Int
        ),
        (
            source      = from(1:5) |> tap(_ -> release!(global_handler)) |> substitute(String, string, global_handler),
            values      = @ts([ "1", "1", "2", "3", "5", c ]),
            source_type = String
        ),
        (
            source      = from(1:5) |> async(0) |> substitute(String, i -> string(i), SubstituteHandler()),
            values      = @ts([ "1" ] ~ [ "1" ] ~ [ "1" ] ~ [ "1" ] ~ [ "1" ] ~ c),
            source_type = Int
        ),
    ])

end

end
