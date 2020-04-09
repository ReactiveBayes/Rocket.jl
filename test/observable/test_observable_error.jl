module RocketErrorObservableTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "ErrorObservable" begin

    @testset begin
        @test throwError(1)      == ErrorObservable{Any}(1)
        @test throwError(1, Int) == ErrorObservable{Int}(1)

        @test throwError("Error")      == throwError("Error")
        @test throwError("Error", Int) != throwError("Error", Float64)
    end

    @testset begin
        source = throwError("Error", Int)
        io = IOBuffer()

        show(io, source)

        printed = String(take!(io))

        @test occursin("ErrorObservable", printed)
        @test occursin(string(eltype(source)), printed)
    end

    run_testset([
        (
            source = throwError(0),
            values = @ts(e(0))
        )
    ])

end

end
