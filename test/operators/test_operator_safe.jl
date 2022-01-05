module RocketSafeOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: safe()" begin

    println("Testing: operator safe()")

    run_testset([
        (
            source = from_iterable(1:5) |> safe(),
            values = @ts([ 1:5, c ])
        ),
        (
            source = from_iterable([ 0, 1, 2 ]) |> safe() |> map(OpType(Int), d -> d === 0 ? 0 : throw(d)),
            values = @ts([ 0, e(1) ])
        ),
        (
            source = completed() |> safe(),
            values = @ts(c)
        ),
        (
            source = faulted("e") |> safe(),
            values = @ts(e("e"))
        ),
        (
            source = never() |> safe(),
            values = @ts()
        )
    ])

end

end
