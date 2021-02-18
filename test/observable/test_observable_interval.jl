module RocketIntervalObservableTest

using Test
using Rocket

@testset "IntervalObservable" begin

    println("Testing: interval")

    @testset begin
        @test interval(100) == Rocket.TimerObservable(100, 100)
    end

end

end
