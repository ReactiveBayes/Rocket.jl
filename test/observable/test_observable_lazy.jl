module RocketLazyObservableTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "LazyObservable" begin

    println("Testing: lazy")

    @testset begin
    
        values = []
        stream = lazy(Int)
        subscription = subscribe!(stream, (x) -> push!(values, x))
        set!(stream, from(1:3))
        @test values == [ 1, 2, 3 ]
        subscription = subscribe!(stream, (x) -> push!(values, x))
        @test values == [ 1, 2, 3, 1, 2, 3 ]

    end

    @testset begin
    
        values = []
        stream = lazy(Int)
        subscription = subscribe!(stream, (x) -> push!(values, x))
        unsubscribe!(subscription)
        set!(stream, from(1:3))
        @test values == [ ]
        subscription = subscribe!(stream, (x) -> push!(values, x))
        @test values == [ 1, 2, 3 ]

    end

    @testset begin
    
        values1 = []
        values2 = []
        stream = lazy(Int)
        subscription1 = subscribe!(stream, (x) -> push!(values1, x))
        subscription2 = subscribe!(stream, (x) -> push!(values2, x))
        set!(stream, from(1:3))
        @test values1 == [ 1, 2, 3 ]
        @test values2 == [ 1, 2, 3 ]

    end

    @testset begin
    
        values1 = []
        values2 = []
        stream = lazy(Int)
        subscription1 = subscribe!(stream, (x) -> push!(values1, x))
        subscription2 = subscribe!(stream, (x) -> push!(values2, x))
        unsubscribe!(subscription1)
        set!(stream, from(1:3))
        @test values1 == [ ]
        @test values2 == [ 1, 2, 3 ]

    end

    @testset begin
    
        values1 = []
        values2 = []
        stream = lazy(Int)
        subscription1 = subscribe!(stream, (x) -> push!(values1, x))
        subscription2 = subscribe!(stream, (x) -> push!(values2, x))
        unsubscribe!(subscription2)
        set!(stream, from(1:3))
        @test values1 == [ 1, 2, 3]
        @test values2 == [ ]

    end

    @testset begin
    
        values = []
        stream = lazy(Int)
        subject = Subject(Int)
        next!(subject, 1)
        subscription = subscribe!(stream, (x) -> push!(values, x))
        set!(stream, subject)
        @test values == [ ]
        next!(subject, 2)
        @test values == [ 2 ]
        unsubscribe!(subscription)
        next!(subject, 3)
        @test values == [ 2 ]

    end

    
end

end
