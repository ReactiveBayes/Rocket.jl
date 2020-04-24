module RocketTakeOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: take()" begin

    run_proxyshowcheck("Take", take(1))

    run_testset([
        (
            source = from(1:5) |> take(3),
            values = @ts([ 1:3, c ])
        ),
        (
            source = from(1:5) |> take(0),
            values = @ts(c)
        ),
        (
            source = from(1:5) |> async() |> take(3),
            values = @ts([ 1 ] ~ [ 2 ] ~ [ 3, c ])
        ),
        (
            source = timer(100, 30) |> take(3),
            values = @ts(100 ~ [ 0 ] ~ 30 ~ [ 1 ] ~ 30 ~ [ 2, c ])
        ),
        (
            source = completed() |> take(10),
            values = @ts(c)
        ),
        (
            source = throwError("e") |> take(10),
            values = @ts(e("e"))
        ),
        (
            source = never() |> take(10),
            values = @ts()
        )
    ])

end

end
