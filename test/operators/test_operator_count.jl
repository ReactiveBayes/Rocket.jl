module RocketCountOperatorTest

using Test
using Rocket

include("./testset.jl")

@testset "operator: count()" begin

    run_testset([
        (
            source = from(1:42) |> count(),
            values = [ 42 ]
        ),
        (
            source = completed(Int) |> count(),
            values = [ 0 ]
        )
    ])

end

end
