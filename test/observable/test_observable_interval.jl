module RxIntervalObservableTest

using Test
using Rx

@testset "IntervalObservable" begin

    @testset begin
        @test interval(100) == TimerObservable(100, 100)
    end

end

end
