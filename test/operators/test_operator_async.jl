module RocketAsyncOperatorTest

using Test
using Rocket

include("./test_helpers.jl")

@testset "operator: async()" begin

    run_testset([
        (
            source = from(1:5),
            values = @ts([1, 2, 3, 4, 5] ~ c)
        ),
        (
            source = from(1:5) |> async(),
            values = @ts([1] ~ [2] ~ [3] ~ [4] ~ [5] ~ c)
        ),
        (
            source = completed() |> async(),
            values = @ts(c)
        ),
        (
            source = throwError("e") |> async(),
            values = @ts(e("e")),
        ),
        (
            source = never() |> uppercase(),
            values = @ts()
        )
    ])

end

end
