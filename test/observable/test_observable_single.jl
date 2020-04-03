module RocketSingleObservableTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "SingleObservable" begin

    @testset begin
        @test of(1)               == SingleObservable{Int}(1)
        @test of([ 1, 2, 3 ])     == SingleObservable{Vector{Int}}([ 1, 2, 3 ])
        @test of(( 1, 2, 3 ))     == SingleObservable{Tuple{Int, Int, Int}}(( 1, 2, 3 ))
        @test of("Hello, world!") == SingleObservable{String}("Hello, world!")
        @test of('H')             == SingleObservable{Char}('H')
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
