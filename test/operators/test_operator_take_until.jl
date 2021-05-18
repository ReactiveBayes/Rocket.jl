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
            values = @ts(c)
        ),
        (
            source = from(1:5) |> take_until(never()),
            values = @ts([ 1, 2, 3, 4, 5, c])
        ),
        (
            source = from(1:5) |> take_until(completed()),
            values = @ts(c)
        ),
        (
            source = from(1:5) |> take_until(faulted("e")),
            values = @ts(e("e"))
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
            source = faulted(1) |> take_until(of(1)),
            values = @ts(c)
        ),
        (
            source = faulted(1) |> async(0) |> take_until(of(1)),
            values = @ts(c)
        ),
        (
            source = faulted(1) |> take_until(timer(100)),
            values = @ts(e(1))
        ),
        (
            source = faulted(1) |> async(0) |> take_until(timer(100)),
            values = @ts(e(1))
        ),
        (
            source = never() |> take_until(of(1)),
            values = @ts(c)
        ),
        (
            source = never() |> take_until(timer(100)),
            values = @ts(100 ~ c)
        ),
        (
            source = never() |> take_until(never()),
            values = @ts()
        ),
        (
            source = from(1:5) |> take_until(completed()),
            values = @ts(c)
        ),
        (
            source = from(1:5) |> take_until(of(1) |> async()),
            values = @ts([ 1, 2, 3, 4, 5, c ])
        ),
    ])

    s1 = interval(30)

    run_testset([
        (
            source = s1 |> take_until(s1 |> filter(i -> i == 2)),
            values = @ts(30 ~ [ 0 ] ~ 30 ~ [ 1 ] ~ 30 ~ c)
        ),
        (
            source = s1 |> take_until(s1 |> filter(i -> i == 3)),
            values = @ts(30 ~ [ 0 ] ~ 30 ~ [ 1 ] ~ 30 ~ [ 2 ] ~ 30 ~ c)
        ),
        (
            source = s1 |> take_until(completed()),
            values = @ts(c)
        )
    ])

end

end
