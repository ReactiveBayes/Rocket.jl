module RocketTapOnCompleteOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: tap_on_complete()" begin

    completed1 = false
    completed2 = false
    completed3 = false
    completed4 = false

    run_testset([
        (
            source = from(1:5) |> tap_on_complete(() -> completed1 = true),
            values = @ts([ 1:5, c ])
        ),
        (
            source = from(1:5) |> skip_complete() |> tap_on_complete(() -> completed2 = true),
            values = @ts([ 1:5 ])
        ),
        (
            source = throwError(1) |> tap_on_complete(() -> completed3 = true),
            values = @ts(e(1))
        ),
        (
            source = never() |> tap_on_complete(() -> completed4 = true),
            values = @ts()
        )
    ])

    @test completed1 === true
    @test completed2 === false
    @test completed3 === false
    @test completed4 === false

end

end
