module RocketTakeUntilOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: take_until()" begin

    println("Testing: operator take_until()")

    run_proxyshowcheck("TakeUntil", take_until(never()), args = (check_subscription = true, ))

    run_testset([
        (
            source = from(1:5) |> take_until(of(1)),
            values = @ts([ 1:5, c ])
        ),
        (
            source = from(1:5) |> async(0) |> take_until(of(1)),
            values = @ts(c)
        ),
        (
            source = timer(10, 1000) |> take_until(timer(100)),
            values = @ts([ 0 ] ~ c)
        ),
        (
            source = completed() |> take_until(of(1)),
            values = @ts(c)
        ),
        (
            source = completed() |> async(0) |> take_until(of(1)),
            values = @ts(c)
        ),
        (
            source = completed() |> take_until(timer(100)),
            values = @ts(c)
        ),
        (
            source = completed() |> async(0) |> take_until(timer(100)),
            values = @ts(c)
        ),
        (
            source = throwError(1) |> take_until(of(1)),
            values = @ts(e(1))
        ),
        (
            source = throwError(1) |> async(0) |> take_until(of(1)),
            values = @ts(c)
        ),
        (
            source = throwError(1) |> take_until(timer(100)),
            values = @ts(e(1))
        ),
        (
            source = throwError(1) |> async(0) |> take_until(timer(100)),
            values = @ts(e(1))
        ),
        (
            source = never() |> take_until(of(1)),
            values = @ts(c)
        ),
        (
            source = never() |> take_until(timer(100)),
            values = @ts(100 ~ c)
        )
    ])

end

end
