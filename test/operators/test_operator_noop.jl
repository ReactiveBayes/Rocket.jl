module RocketNoopOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: noop()" begin

    run_proxyshowcheck("Noop", noop())

    source = from(1:5)

    for i in 1:1000
        source = source |> map(Int, d -> d + 1) |> noop()
    end

    run_testset([
        (
            source = source,
            values = @ts([ 1001, 1002, 1003, 1004, 1005, c ])
        ),
        (
            source = completed() |> noop(),
            values = @ts(c)
        ),
        (
            source = throwError(1) |> noop(),
            values = @ts(e(1))
        ),
        (
            source = never() |> noop(),
            values = @ts()
        )
    ], check_timings = false)

end

end
