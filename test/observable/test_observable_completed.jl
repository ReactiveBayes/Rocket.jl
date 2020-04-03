module RocketCompleteObservableTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "CompletedObservable" begin

    @testset begin
        @test completed()    == CompletedObservable{Any}()
        @test completed(Int) == CompletedObservable{Int}()
    end

    run_testset([
        (
            source = completed(),
            values = @ts(c)
        )
    ])

end

end
