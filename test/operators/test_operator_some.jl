module RocketSomeOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: some()" begin

    println("Testing: operator some()")

    run_proxyshowcheck("Some", some())

    run_testset([
        (source = from(1:42) |> max() |> some(), values = @ts([42, c]), source_type = Int),
        (
            source = from([2, 3, 4, nothing]) |> some(),
            values = @ts([2, 3, 4, c]),
            source_type = Int,
        ),
        (source = completed() |> skip_next(), values = @ts(c)),
        (source = completed(Int) |> max() |> some(), values = @ts(c), source_type = Int),
        (source = faulted(1) |> skip_next(), values = @ts(e(1))),
        (source = never() |> skip_next(), values = @ts()),
    ])

    @testset begin
        @test_throws Exception of(1) |> some()
    end

end

end
