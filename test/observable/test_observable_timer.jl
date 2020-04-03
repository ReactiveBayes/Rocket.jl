module RocketTimerObservableTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "TimerObservable" begin

    @testset begin
        @test timer(100, 100) == Rocket.TimerObservable{100, 100}()
    end

    run_testset([
        (
            source = timer(100, 30) |> take(3),
            values = @ts(100 ~ [ 0 ] ~ 30 ~ [ 1 ] ~ 30 ~ [ 2, c ] )
        ),
        (
            source = timer(100),
            values = @ts(100 ~ [ 0, c ])
        )
    ])

end

end
