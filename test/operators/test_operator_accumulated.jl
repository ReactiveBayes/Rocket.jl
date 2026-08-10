module RocketAccumulatedOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: accumulated()" begin

    println("Testing: operator accumulated()")

    run_proxyshowcheck("Accumulated", accumulated())

    run_testset([
        (
            source = from(1:3) |> accumulated(),
            values = @ts([[1], [1, 2], [1, 2, 3], c]),
            source_type = Vector{Int},
        ),
        (
            source = from(["a", "b", "c"]) |> accumulated(),
            values = @ts([["a"], ["a", "b"], ["a", "b", "c"], c]),
            source_type = Vector{String},
        ),
        (
            source = completed(Int) |> accumulated(),
            values = @ts(c),
            source_type = Vector{Int},
        ),
        (
            source = faulted(Int, "e") |> accumulated(),
            values = @ts(e("e")),
            source_type = Vector{Int},
        ),
        (source = never(Int) |> accumulated(), values = @ts(), source_type = Vector{Int}),
    ])

    @testset "Issue #74: copy keyword controls snapshot aliasing" begin
        # copy = true (default): every retained emission is an independent snapshot
        let retained = Vector{Vector{Int}}()
            subscribe!(from(1:4) |> accumulated(), lambda(on_next = v -> push!(retained, v)))
            @test retained == [[1], [1, 2], [1, 2, 3], [1, 2, 3, 4]]
            @test retained[1] == [1]                 # unchanged after later emissions
            @test retained[1] !== retained[end]      # distinct objects
        end

        # copy = false: the live accumulator is forwarded by reference (documented gotcha)
        let retained = Vector{Vector{Int}}()
            subscribe!(
                from(1:4) |> accumulated(copy = false),
                lambda(on_next = v -> push!(retained, v)),
            )
            @test all(x -> x === retained[1], retained)  # all alias one growing vector
            @test retained[1] == [1, 2, 3, 4]            # reflects final accumulated state
        end
    end

end

end
