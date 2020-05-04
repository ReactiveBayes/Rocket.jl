module RocketSwitchMapToOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: switch_map_to()" begin

    println("Testing: operator switch_map_to()")

    struct DummyType end

    @testset begin
        @test_throws InvalidSubscribableTraitUsageError of(0) |> switch_map_to(DummyType())
    end

    run_testset([
        (
            source      = from([ 0, 0 ]) |> switch_map_to(from([ 1, 2 ])),
            values      = @ts([ 1, 2, 1, 2, c ]),
            source_type = Int
        ),
        (
            source      = from(1:5) |> switch_map_to(of(0.0)),
            values      = @ts([ 0.0, 0.0, 0.0, 0.0, 0.0, c ]),
            source_type = Float64
        ),
        (
            source      = completed() |> switch_map_to(of(0)),
            values      = @ts(c),
            source_type = Int
        ),
        (
            source      = throwError(String, "e") |> switch_map_to(of(0)),
            values      = @ts(e("e")),
            source_type = Int
        ),
        (
            source      = never() |> switch_map_to(of(0)),
            values      = @ts(),
            source_type = Int
        ),
        (
            source      = from([ 0, 0 ]) |> async(0) |> switch_map_to(from([ 1, 2 ])),
            values      = @ts([ 1, 2 ] ~ [ 1, 2 ] ~ c),
            source_type = Int
        ),
        (
            source      = from([ of(1), completed(Int), of(2) ]) |> switch_map_to(of(0)),
            values      = @ts([ 0, 0, 0, c ]),
            source_type = Int
        ),
        (
            source      = from([ of(1), completed(Int), of(2) ]) |> switch_map(Int) |> switch_map_to(of(0)),
            values      = @ts([ 0, 0, c ]),
            source_type = Int
        ),
        (
            source      = from([ of(1), throwError(Int, "err"), of(2) ]) |> switch_map_to(of(0)),
            values      = @ts([ 0, 0, 0, c ]),
            source_type = Int
        ),
        (
            source      = from([ of(1), throwError(Int, "err"), of(2) ]) |> switch_map(Int) |> switch_map_to(of(0)),
            values      = @ts([ 0, e("err") ]),
            source_type = Int
        )
    ])

end

end
