module RocketFaultedObservableTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "FaultedObservable" begin

    println("Testing: faulted")

    struct DummyScheduler <: Rocket.AbstractScheduler end

    @testset begin
        @test faulted(1) == FaultedObservable{Any,AsapScheduler}(1, AsapScheduler())
        @test faulted(Int, 1) == FaultedObservable{Int,AsapScheduler}(1, AsapScheduler())

        @test faulted("Error") == faulted("Error")
        @test faulted(Int, "Error") != faulted(Float64, "Error")

        @test faulted(1; scheduler = DummyScheduler()) ==
              FaultedObservable{Any,DummyScheduler}(1, DummyScheduler())

        @test_throws ErrorException faulted(Int)
        @test_throws ErrorException faulted(Float64)
    end

    @testset begin
        source = faulted(Int, "Error")
        io = IOBuffer()

        show(io, source)

        printed = String(take!(io))

        @test occursin("FaultedObservable", printed)
        @test occursin(string(eltype(source)), printed)
    end

    run_testset([
        (source = faulted(0), values = @ts(e(0))),
        (source = faulted(0, scheduler = AsyncScheduler(0)), values = @ts(0 ~ e(0))),
    ])

end

end
