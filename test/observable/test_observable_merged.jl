module RocketMergedObservableTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "MergeObservable" begin

    run_testset([
        (
            source = merged((of(1), of(2.0))),
            values = @ts([ 1, 2.0, c ]),
            source_type = Union{Int, Float64}
        ),
        (
            source = merged((of(2.0), from("Hello"), from("World") |> async())) |> take(10),
            values = @ts([ 2.0, 'H', 'e', 'l', 'l', 'o' ] ~ [ 'W' ] ~ [ 'o' ] ~ [ 'r' ] ~ [ 'l', c ]),
            source_type = Union{Float64, Char}
        )
    ])

end

end
