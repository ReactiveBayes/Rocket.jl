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
            source = merged((timer(100, 30), of(2.0), from("Hello"))) |> take(10),
            values = @ts([ 2.0, 'H', 'e', 'l', 'l', 'o' ] ~ [ 0 ] ~ 30 ~ [ 1 ] ~ 30 ~ [ 2 ] ~ 30 ~ [ 3, c ])
        )
    ])

end

end
