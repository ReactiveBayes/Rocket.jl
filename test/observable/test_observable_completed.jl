module RocketCompleteObservableTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "CompletedObservable" begin

    println("Testing: completed")

    struct DummyScheduler <: Rocket.AbstractScheduler end

    @testset begin
        @test completed()    == CompletedObservable{Any, AsapScheduler}(AsapScheduler())
        @test completed(Int) == CompletedObservable{Int, AsapScheduler}(AsapScheduler())
        @test completed(Int) == completed(Int)
        @test completed(Int) != completed(Float64)

        @test completed(Int; scheduler = DummyScheduler()) == CompletedObservable{Int, DummyScheduler}(DummyScheduler())
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
