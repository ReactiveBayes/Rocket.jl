module RocketDelayOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: delay()" begin

    run_proxyshowcheck("Delay", delay(0), args = (check_subscription = true, ))

    run_testset([
        (
            source = of(2) |> delay(50),
            values = @ts(50 ~ [ 2 ] ~ c)
        ),
        (
            source = completed(Int) |> delay(50),
            values = @ts(50 ~ c)
        ),
        (
            source = throwError("e") |> delay(50),
            values = @ts(50 ~ e("e"))
        ),
        (
            source = never() |> delay(50),
            values = @ts()
        )
    ])

end

end
