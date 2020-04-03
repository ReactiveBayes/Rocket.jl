module RocketErrorObservableTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "ErrorObservable" begin

    @testset begin
        @test throwError(1)      == ErrorObservable{Any}(1)
        @test throwError(1, Int) == ErrorObservable{Int}(1)
    end

    run_testset([
        (
            source = throwError(0),
            values = @ts(e(0))
        )
    ])

end

end
