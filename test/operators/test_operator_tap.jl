module RocketTapOperatorTest

using Test
using Rocket

include("./test_helpers.jl")

@testset "operator: tap()" begin

    sideeffects1 = []
    sideeffects2 = []
    sideeffects3 = []
    sideeffects4 = []

    run_testset([
        (
            source = from(1:5) |> tap_on_subscribe(() -> sideeffects1 = []) |> tap((d) -> push!(sideeffects1, d)),
            values = @ts([ 1:5, c ])
        ),
        (
            source = from(1:5) |> tap_on_subscribe(() -> sideeffects2 = []) |> tap((d) -> push!(sideeffects2, d)) |> skip_next(),
            values = @ts(c)
        ),
        (
            source = throwError(1) |> tap_on_subscribe(() -> sideeffects3 = []) |> tap((d) -> push!(sideeffects3, d)),
            values = @ts(e(1))
        ),
        (
            source = never() |> tap_on_subscribe(() -> sideeffects4 = []) |> tap((d) -> push!(sideeffects4, d)),
            values = @ts()
        )
    ])

    @test sideeffects1 == [ 1, 2, 3, 4, 5 ]
    @test sideeffects2 == [ 1, 2, 3, 4, 5 ]
    @test sideeffects3 == []
    @test sideeffects4 == []

end

end
