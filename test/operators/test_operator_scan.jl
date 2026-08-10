module RocketScanOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: scan()" begin

    println("Testing: operator scan()")

    run_proxyshowcheck("Scan", scan(Any, +, 0))
    run_proxyshowcheck("ScanNoSeed", scan(+))

    run_testset([
        (
            source = from(1:5) |> scan(Int, +, 1),
            values = @ts([2, 4, 7, 11, 16, c]),
            source_type = Int,
        ),
        (
            source = from(1:5) |> scan(+),
            values = @ts([1, 3, 6, 10, 15, c]),
            source_type = Int,
        ),
        (
            source = from(1:5) |> scan(Vector{Int}, (d, c) -> [c..., d], Int[]),
            values = @ts([[1], [1, 2], [1, 2, 3], [1, 2, 3, 4], [1, 2, 3, 4, 5], c]),
            source_type = Vector{Int},
        ),
        (source = completed(Int) |> scan(+), values = @ts(c), source_type = Int),
        (source = completed(Int) |> scan(Int, +, 2), values = @ts(c), source_type = Int),
        (source = faulted("e") |> scan(+), values = @ts(e("e"))),
        (source = never() |> scan(+), values = @ts()),
    ])

    @testset "Issue #77: no-seed scan does not treat a real `nothing` as a missing seed" begin
        values = Any[]
        subscribe!(
            from(Any[nothing, 1, 2]) |> scan((d, c) -> (d, c)),
            lambda(on_next = v -> push!(values, v)),
        )
        # previously the leading `nothing` was mistaken for "no seed yet", so `1` was
        # re-used as the seed and the (1, nothing) accumulation step was lost
        @test values == [nothing, (1, nothing), (2, (1, nothing))]
    end

end

end
