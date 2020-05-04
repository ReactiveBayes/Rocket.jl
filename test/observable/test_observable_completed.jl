module RocketCompleteObservableTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "CompletedObservable" begin

    println("Testing: completed")

    @testset begin
        @test completed()    == CompletedObservable{Any}()
        @test completed(Int) == CompletedObservable{Int}()
        @test completed(Int) == completed(Int)
        @test completed(Int) != completed(Float64)
    end

    @testset begin
        source = completed(Int)
        io = IOBuffer()

        show(io, source)

        printed = String(take!(io))

        @test occursin("CompletedObservable", printed)
        @test occursin(string(eltype(source)), printed)
    end

    run_testset([
        (
            source = completed(),
            values = @ts(c)
        )
    ])

end

end
