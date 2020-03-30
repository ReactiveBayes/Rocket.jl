module RocketIntervalObservableTest

using Test
using Rocket

@testset "IntervalObservable" begin

    @testset begin
        @test interval(100) == Rocket.TimerObservable{100, 100}()
    end

end

end
