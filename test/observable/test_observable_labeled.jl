module RocketLabeledObservableTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "LabeledObservable" begin

    @testset begin
        @test labeled(Val((:x, )), from([ (1, ), (2, ), (3, ) ])) isa LabeledObservable{NamedTuple{(:x, ), Tuple{Int}}}
        @test labeled(Val((:x, :y)), from([ (1, 1.0), (2, 2.0), (3, 3.0) ])) isa LabeledObservable{NamedTuple{(:x, :y), Tuple{Int, Float64}}}
    end

    @testset begin
        source = labeled(Val((:x, )), from([ (1, ), (2, ), (3, ) ]))
        io = IOBuffer()

        show(io, source)

        printed = String(take!(io))

        @test occursin("LabeledObservable", printed)
        @test occursin(string(eltype(source)), printed)
    end

    run_testset([
        (
            source = labeled(Val((:x, )), from([ (1, ), (2, ), (3, ) ])),
            values = @ts([ (x = 1, ), (x = 2, ), (x = 3, ), c ]),
            source_type = NamedTuple{(:x, ), Tuple{Int}}
        ),
        (
            source = labeled(Val((:x, :y)), from([ (1, 2.0), (2, 3.0), (3, 4.0) ])),
            values = @ts([ (x = 1, y = 2.0), (x = 2, y = 3.0), (x = 3, y = 4.0), c ]),
            source_type = NamedTuple{(:x, :y), Tuple{Int, Float64}}
        ),
    ])

end

end
