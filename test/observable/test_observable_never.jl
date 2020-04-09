module RocketNeverObservableTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "NeverObservable" begin

    @testset begin
        @test never()    == NeverObservable{Any}()
        @test never(Int) == NeverObservable{Int}()
        @test never(Int) == never(Int)
        @test never(Int) != never(Float64)
    end

    @testset begin
        source = never(Int)
        io = IOBuffer()

        show(io, source)

        printed = String(take!(io))

        @test occursin("NeverObservable", printed)
        @test occursin(string(eltype(source)), printed)
    end

    run_testset([
        (
            source = never(),
            values = @ts()
        )
    ])

end

end
