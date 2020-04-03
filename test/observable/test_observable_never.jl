module RocketNeverObservableTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "NeverObservable" begin

    @testset begin
        @test never()    == NeverObservable{Any}()
        @test never(Int) == NeverObservable{Int}()
    end

    run_testset([
        (
            source = never(),
            values = @ts()
        )
    ])

end

end
