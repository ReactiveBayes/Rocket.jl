module RocketErrorIfEmptyOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: error_if_empty()" begin

    println("Testing: operator error_if_empty()")

    run_proxyshowcheck("ErrorIfEmpty", error_if_empty(0))

    run_testset([
        (
            source = from(1:5) |> error_if_empty("Empty"),
            values = @ts([1:5, c]),
            source_type = Int,
        ),
        (
            source = completed(Int) |> error_if_empty("Empty"),
            values = @ts(e("Empty")),
            source_type = Int,
        ),
        (
            source = faulted(Int, "e") |> error_if_empty("Empty"),
            values = @ts(e("e")),
            source_type = Int,
        ),
        (source = never(Int) |> error_if_empty("Empty"), values = @ts(), source_type = Int),
        (
            source = completed(Int) |>
                     error_if_empty("Empty") |>
                     catch_error((d, obs) -> of(1)),
            values = @ts([1, c]),
            source_type = Int,
        ),
    ])

end

end
