module RocketGenerateObservableTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "GenerateObservable" begin

    println("Testing: generate")

    @testset begin
        source = generate(1, x -> x < 2, x -> x + 1)
        io = IOBuffer()

        show(io, source)

        printed = String(take!(io))

        @test occursin("GenerateObservable", printed)
        @test occursin(string(eltype(source)), printed)
    end

    run_testset([
        (
            source = generate(1, x -> x < 3, x -> x + 1),
            values = @ts([1, 2, c]),
            source_type = Int,
        ),
        (
            source = generate(1.0, x -> x < 0.5, x -> x + 1.0),
            values = @ts(c),
            source_type = Float64,
        ),
        (
            source = generate(1.0, x -> false, x -> x),
            values = @ts(c),
            source_type = Float64,
        ),
        (
            source = generate(1, x -> x < 2, x -> x + 1, scheduler = AsyncScheduler(0)),
            values = @ts([1] ~ c),
            source_type = Int,
        ),
    ])

end

end
