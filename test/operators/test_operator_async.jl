module RocketAsyncOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: async()" begin

    println("Testing: operator async()")

    run_testset([
        (
            source = from(1:5),
            values = @ts([1, 2, 3, 4, 5, c])
        ),
        (
            source = from(1:5) |> async(),
            values = @ts(0 ~ [ 1, 2, 3, 4, 5, c ])
        ),
        (
            source = from(1:5) |> async(0),
            values = @ts([1] ~ [2] ~ [3] ~ [4] ~ [5] ~ c)
        ),
        (
            source = from(1:5) |> async(1),
            values = @ts([1] ~ [2] ~ [3] ~ [4] ~ [5] ~ c)
        ),
        (
            source = from(1:5) |> async(2),
            values = @ts([ 1, 2 ] ~ [ 3, 4 ] ~ [ 5, c ])
        ),
        (
            source = from(1:5) |> async(3),
            values = @ts([ 1, 2, 3 ] ~ [ 4, 5, c ])
        ),
        (
            source = completed() |> async(0),
            values = @ts(c)
        ),
        (
            source = faulted("e") |> async(0),
            values = @ts(e("e")),
        ),
        (
            source = never() |> async(0),
            values = @ts()
        )
    ])

end

end
