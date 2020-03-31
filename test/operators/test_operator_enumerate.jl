module RocketEnumerateOperatorTest

using Test
using Rocket

include("./testset.jl")

@testset "operator: enumerate()" begin

    run_testset([
        (
            source = from([ 3, 2, 1 ]) |> enumerate(),
            values = [ (3, 1), (2, 2), (1, 3) ]
        ),
        (
            source = completed(Int) |> enumerate(),
            values = []
        )
    ])

end

end
