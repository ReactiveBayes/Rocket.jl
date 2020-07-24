module RocketWithLatestOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: with_latest()" begin

    println("Testing: operator with_latest()")

    run_testset([
        (
            source = of(0) |> with_latest(of(0.0)),
            values = @ts([ (0, 0.0), c ]),
            source_type = Tuple{Int, Float64}
        ),
        (
            source = of(0) |> with_latest(of(0.0), of('0')),
            values = @ts([ (0, 0.0, '0'), c ]),
            source_type = Tuple{Int, Float64, Char}
        ),
        (
            source = from(1:5) |> with_latest(of(1)),
            values = @ts([ (1, 1), (2, 1), (3, 1), (4, 1), (5, 1), c ])
        ),
        (
            source = from(1:2) |> async(0) |> with_latest(from(1:2) |> async(0)),
            values = @ts([ (1, 1) ] ~ [ (2, 2) ] ~ c)
        ),
        (
            source = from(1:2) |> with_latest(completed()),
            values = @ts(c)
        ),
        (
            source = completed(Int) |> with_latest(of(1)),
            values = @ts(c)
        ),
        (
            source = completed(Int) |> with_latest(faulted("e")),
            values = @ts(e("e"))
        ),
        (
            source = completed() |> with_latest(completed()),
            values = @ts(c)
        ),
        (
            source = completed() |> with_latest(never()),
            values = @ts(c)
        ),
        (
            source = completed(Int) |> with_latest(of(1) |> async(0)),
            values = @ts(c)
        ),
        (
            source = never(Int) |> with_latest(of(1)),
            values = @ts()
        ),
        (
            source = never() |> with_latest(completed()),
            values = @ts(c)
        ),
        (
            source = never() |> with_latest(never()),
            values = @ts()
        ),
        (
            source = never() |> with_latest(faulted("e")),
            values = @ts(e("e"))
        ),
        (
            source = faulted("e") |> with_latest(of(1), of(2)),
            values = @ts(e("e"))
        ),
        (
            source = faulted("e") |> with_latest(faulted("e2")),
            values = @ts(e("e2"))
        ),
        (
            source = faulted("e") |> with_latest(completed()),
            values = @ts(c)
        ),
        (
            source = faulted("e") |> with_latest(never()),
            values = @ts(e("e"))
        )
    ])

end

end
