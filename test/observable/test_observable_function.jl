module RocketFunctionObservableTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "FunctionObservable" begin

    println("Testing: make")

    @testset begin
        source = make(Int) do actor
            next!(actor, 0)
            complete!(actor)
        end

        io = IOBuffer()

        show(io, source)

        printed = String(take!(io))

        @test occursin("FunctionObservable", printed)
        @test occursin(string(eltype(source)), printed)

        subscription = subscribe!(source, void())

        show(io, subscription)

        printed = String(take!(io))

        @test occursin("FunctionObservableSubscription", printed)

        unsubscribe!(subscription)
    end

    source1 = make(Int) do actor
        complete!(actor)
    end

    source2 = make(Float64) do actor
        setTimeout(100) do
            complete!(actor)
        end
    end

    source3 = make(Int) do actor
        next!(actor, 1)
        setTimeout(100) do
            complete!(actor)
        end
    end

    source4 = make(Int) do actor
        next!(actor, 1)
        setTimeout(100) do
            next!(actor, 2)
            complete!(actor)
        end
    end

    source5 = make(Int) do actor
        next!(actor, 1)
        setTimeout(100) do
            next!(actor, 2)
            error!(actor, "Error")
        end
    end

    run_testset([
        (
            source = source1,
            values = @ts(c),
            source_type = Int
        ),
        (
            source = source2,
            values = @ts(100 ~ c),
            source_type = Float64
        ),
        (
            source = source3,
            values = @ts([ 1 ] ~ 100 ~ c),
            source_type = Int
        ),
        (
            source = source4,
            values = @ts([ 1 ] ~ 100 ~ [ 2, c ]),
            source_type = Int
        ),
        (
            source = source5,
            values = @ts([ 1 ] ~ 100 ~ [ 2, e("Error") ]),
            source_type = Int
        )
    ])

end

end
