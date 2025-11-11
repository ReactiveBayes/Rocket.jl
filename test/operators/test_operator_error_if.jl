module RocketErrorIfOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: error_if()" begin

    println("Testing: operator error_if()")

    run_proxyshowcheck("ErrorIf", error_if((d) -> false))

    run_testset([
        (
            source = from(1:42) |> error_if((d) -> d > 2),
            values = @ts([1, 2, e]),
            source_type = Int,
        ),
        (
            source = from(1:42) |> error_if((d) -> d > 2, (d) -> "Error $d"),
            values = @ts([1, 2, e("Error 3")]),
            source_type = Int,
        ),
        (
            source = from(1:42) |> error_if((d) -> d > 5, (d) -> "Error $d"),
            values = @ts([1, 2, 3, 4, 5, e("Error 6")]),
            source_type = Int,
        ),
        (
            source = from(1:42) |>
                     error_if((d) -> d > 2) |>
                     catch_error((err, obs) -> of(3)),
            values = @ts([1, 2, 3, c]),
            source_type = Int,
        ),
        (
            source = completed(Int) |> error_if((d) -> d > 2),
            values = @ts(c),
            source_type = Int,
        ),
        (
            source = faulted(String, "e") |> error_if((d) -> d > 2),
            values = @ts(e("e")),
            source_type = String,
        ),
        (source = never() |> error_if((d) -> d > 2), values = @ts()),
    ])

    @testset "`error_if` should unsubscribe on check fail" begin
        source = Subject(Int)

        events = []

        subscription = subscribe!(
            source |> error_if((d) -> d > 2),
            lambda(
                on_next = (d) -> push!(events, d),
                on_error = (e) -> push!(events, "Error"),
                on_complete = () -> push!(events, "Completed"),
            ),
        )

        @test events == []

        next!(source, 1)

        @test events == [1]

        next!(source, 2)

        @test events == [1, 2]

        next!(source, 3)

        @test events == [1, 2, "Error"]

        next!(source, 4)

        @test events == [1, 2, "Error"]

        unsubscribe!(subscription)

        @test events == [1, 2, "Error"]
    end

    @testset "`error_if` should not check anything after unsubscription" begin
        source = Subject(Int)

        events = []

        subscription = subscribe!(
            source |> error_if((d) -> d > 2),
            lambda(
                on_next = (d) -> push!(events, d),
                on_error = (e) -> push!(events, "Error"),
                on_complete = () -> push!(events, "Completed"),
            ),
        )

        @test events == []

        next!(source, 1)

        @test events == [1]

        next!(source, 2)

        @test events == [1, 2]

        unsubscribe!(subscription)

        next!(source, 3)

        @test events == [1, 2]

        next!(source, 4)

        @test events == [1, 2]
    end

end

end
