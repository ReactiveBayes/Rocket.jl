module RocketErrorObservableTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "ErrorObservable" begin

    println("Testing: throwError")

    @testset begin
        @test throwError(1)      == ErrorObservable{Any}(1)
        @test throwError(Int, 1) == ErrorObservable{Int}(1)

        @test throwError("Error")      == throwError("Error")
        @test throwError(Int, "Error") != throwError(Float64, "Error")
    end

    @testset begin
        source = throwError(Int, "Error")
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
