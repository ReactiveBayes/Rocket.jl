module RocketTimerObservableTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "TimerObservable" begin

    println("Testing: timer")

    @testset "Constructor" begin
        @test timer(100, 100) == Rocket.TimerObservable(100, 100)
    end

    @testset begin
        source = timer(42, 13)

        io = IOBuffer()

        show(io, source)

        printed = String(take!(io))

        @test occursin("TimerObservable", printed)
        @test occursin("42", printed)
        @test occursin("13", printed)

        subscription = subscribe!(source, void())

        show(io, subscription)

        printed = String(take!(io))

        @test occursin("TimerSubscription", printed)

        unsubscribe!(subscription)
    end

    run_testset([
        (
            source = timer(100, 30) |> take(3),
            values = @ts(100 ~ [0] ~ 30 ~ [1] ~ 30 ~ [2, c])
        ),
        (source = timer(100), values = @ts(100 ~ [0, c])),
    ])

end

end
