module RocketDefaultIfEmptyOperatorTest

using Test
using Rocket

include("./testset.jl")

@testset "operator: default_if_empty()" begin

    run_testset([
        (
            source = from(1:5) |> default_if_empty(0),
            values = [ 1, 2, 3, 4, 5 ]
        ),
        (
            source = completed(Int) |> default_if_empty(0)
            values = [ 0 ]
        )
    ])

end

end
