module RocketDeferObservableTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "DeferObservable" begin

    println("Testing: defer")

    @testset begin
        source = defer(Int, () -> of(1))
        io = IOBuffer()

        show(io, source)

        printed = String(take!(io))

        @test occursin("DeferObservable", printed)
        @test occursin(string(eltype(source)), printed)
    end

    run_testset([
        (
            source = defer(Int, () -> of(1)),
            values = @ts([ 1, c ])
        )
    ])

    @testset begin
        value = 1
        source = defer(Int, () -> begin value += 1; return of(value) end)
        values = Vector{Any}()

        actor = lambda(
            on_next     = (d) -> push!(values, d),
            on_error    = (e) -> push!(values, e),
            on_complete = ()  -> push!(values, "completed")
        )

        @test values == []

        subscribe!(source, actor)

        @test values == [ 2, "completed" ]

        subscribe!(source, actor)

        @test values == [ 2, "completed", 3, "completed" ]

    end

end

end
