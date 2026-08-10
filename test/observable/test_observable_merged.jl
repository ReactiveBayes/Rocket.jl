module RocketMergedObservableTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "MergeObservable" begin

    println("Testing: merged")

    @testset begin
        @test_throws Exception merged([of(1), of(2.0)])
    end

    @testset begin
        source = merged((of(1), of(2.0)))

        io = IOBuffer()

        show(io, source)

        printed = String(take!(io))

        @test occursin("MergeObservable", printed)
        @test occursin(string(eltype(source)), printed)

        subscription = subscribe!(source, void())

        show(io, subscription)

        printed = String(take!(io))

        @test occursin("MergeSubscription", printed)

        unsubscribe!(subscription)
    end

    run_testset([
        (
            source = merged((of(1), of(2.0))),
            values = @ts([1, 2.0, c]),
            source_type = Union{Int,Float64},
        ),
        (
            source = merged((of(2.0), from("Hello"), from("World") |> async(0))) |>
                     take(10),
            values = @ts([2.0, 'H', 'e', 'l', 'l', 'o'] ~ ['W'] ~ ['o'] ~ ['r'] ~ ['l', c]),
            source_type = Union{Float64,Char},
        ),
    ])

    @testset "Issue #70: no emissions from siblings after an inner source errors" begin
        sub_a = Subject(Int)
        sub_b = Subject(Int)

        out = Any[]
        subscription = subscribe!(
            merged((sub_a, sub_b)),
            lambda(
                on_next = v -> push!(out, (:next, v)),
                on_error = e -> push!(out, (:error, e)),
            ),
        )

        error!(sub_a, ErrorException("boomA"))
        next!(sub_b, 123)   # must be dropped: the stream is already terminated

        @test count(x -> x[1] === :next, out) == 0
        @test count(x -> x[1] === :error, out) == 1

        unsubscribe!(subscription)
    end

end

end
