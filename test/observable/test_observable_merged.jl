module RocketMergedObservableTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "MergeObservable" begin

    @testset begin
        @test_throws Exception merged([ of(1), of(2.0) ])
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
            values = @ts([ 1, 2.0, c ]),
            source_type = Union{Int, Float64}
        ),
        (
            source = merged((of(2.0), from("Hello"), from("World") |> async())) |> take(10),
            values = @ts([ 2.0, 'H', 'e', 'l', 'l', 'o' ] ~ [ 'W' ] ~ [ 'o' ] ~ [ 'r' ] ~ [ 'l', c ]),
            source_type = Union{Float64, Char}
        )
    ])

end

end
