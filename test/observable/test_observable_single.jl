module RocketSingleObservableTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "SingleObservable" begin

    println("Testing: of")

    struct DummyScheduler <: Rocket.AbstractScheduler end

    @testset begin
        @test of(1)               == SingleObservable{Int, AsapScheduler}(1, AsapScheduler())
        @test of([ 1, 2, 3 ])     == SingleObservable{Vector{Int}, AsapScheduler}([ 1, 2, 3 ], AsapScheduler())
        @test of(( 1, 2, 3 ))     == SingleObservable{Tuple{Int, Int, Int}, AsapScheduler}(( 1, 2, 3 ), AsapScheduler())
        @test of("Hello, world!") == SingleObservable{String, AsapScheduler}("Hello, world!", AsapScheduler())
        @test of('H')             == SingleObservable{Char, AsapScheduler}('H', AsapScheduler())
        @test of('H')             == of('H')
        @test of(0)               != of(0.0)

        @test of(1, scheduler = DummyScheduler()) == SingleObservable{Int, DummyScheduler}(1, DummyScheduler())
    end

    @testset begin
        source = of(1)
        io = IOBuffer()

        show(io, source)

        printed = String(take!(io))

        @test occursin("SingleObservable", printed)
        @test occursin(string(eltype(source)), printed)
    end

    run_testset([
        (
            source = of(1),
            values = @ts([ 1, c ]),
            source_type = Int
        ),
        (
            source = of([ 1, 2, 3 ]),
            values = @ts([ [ 1, 2, 3 ], c ]),
            source_type = Vector{Int}
        ),
        (
            source = of((1, 1.0)),
            values = @ts([ (1, 1.0), c ]),
            source_type = Tuple{Int, Float64}
        ),
        (
            source = of("Hello, world!"),
            values = @ts([ "Hello, world!", c ]),
            source_type = String
        )
    ])

end

end
