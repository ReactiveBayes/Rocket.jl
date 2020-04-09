module RocketDefaultIfEmptyOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: default_if_empty()" begin

    run_proxyshowcheck("DefaultIfEmpty", default_if_empty(0))

    run_testset([
        (
            source = from(1:5) |> default_if_empty(0),
            values = @ts([ 1:5, c ])
        ),
        (
            source = completed(Int) |> default_if_empty(0),
            values = @ts([ 0, c ])
        ),
        (
            source      = completed(Int) |> default_if_empty("string"),
            values      = @ts([ "string", c ]),
            source_type = Union{Int, String}
        ),
        (
            source      = completed(Int) |> default_if_empty(0) |> default_if_empty("string"),
            values      = @ts([ 0, c ]),
            source_type = Union{Int, String}
        ),
        (
            source      = completed(Int) |> default_if_empty("string") |> default_if_empty(0) ,
            values      = @ts([ "string", c ]),
            source_type = Union{Int, String}
        )
    ])

end

end
