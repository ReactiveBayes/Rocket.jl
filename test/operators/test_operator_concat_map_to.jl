module RocketConcatMapToOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: concat_map_to()" begin

    println("Testing: operator concat_map_to()")

    struct DummyType end

    @testset begin
        @test_throws InvalidSubscribableTraitUsageError of(0) |> concat_map_to(DummyType())
    end

    run_testset([
        (
            source = from([0, 0]) |> concat_map_to(from([1, 2])),
            values = @ts([1, 2, 1, 2, c]),
            source_type = Int,
        ),
        (
            source = from(1:5) |> concat_map_to(of(0.0)),
            values = @ts([0.0, 0.0, 0.0, 0.0, 0.0, c]),
            source_type = Float64,
        ),
        (
            source = from(1:5) |> concat_map_to(faulted(Float64, "err")),
            values = @ts(e("err")),
            source_type = Float64,
        ),
        (
            source = from(1:5) |> concat_map_to(completed(Float64)),
            values = @ts(c),
            source_type = Float64,
        ),
        (
            source = from(1:5) |> concat_map_to(never(Float64)),
            values = @ts(),
            source_type = Float64,
        ),
        (source = completed() |> concat_map_to(of(0)), values = @ts(c), source_type = Int),
        (
            source = faulted(String, "e") |> concat_map_to(of(0)),
            values = @ts(e("e")),
            source_type = Int,
        ),
        (source = never() |> concat_map_to(of(0)), values = @ts(), source_type = Int),
        (
            source = from([0, 0]) |> async(0) |> concat_map_to(from([1, 2])),
            values = @ts([1, 2] ~ [1, 2] ~ c),
            source_type = Int,
        ),
        (
            source = from([0, 0]) |> async(0) |> concat_map_to(from([1, 2]) |> async(0)),
            values = @ts([1] ~ [2] ~ [1] ~ [2] ~ c),
            source_type = Int,
        ),
        (
            source = from([of(1), completed(Int), of(2)]) |> concat_map_to(of(0)),
            values = @ts([0, 0, 0, c]),
            source_type = Int,
        ),
        (
            source = from([of(1), completed(Int), of(2)]) |>
                     concat_map(Int) |>
                     concat_map_to(of(0)),
            values = @ts([0, 0, c]),
            source_type = Int,
        ),
        (
            source = from([of(1), faulted(Int, "err"), of(2)]) |> concat_map_to(of(0)),
            values = @ts([0, 0, 0, c]),
            source_type = Int,
        ),
        (
            source = from([of(1), faulted(Int, "err"), of(2)]) |>
                     concat_map(Int) |>
                     concat_map_to(of(0)),
            values = @ts([0, e("err")]),
            source_type = Int,
        ),
    ])

end

end
