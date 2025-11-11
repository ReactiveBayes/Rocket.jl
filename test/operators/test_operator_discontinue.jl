module RocketDiscontinueOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: discontinue()" begin

    println("Testing: operator discontinue()")

    run_proxyshowcheck("Discontinue", discontinue())

    @testset begin
        values = []
        errors = []
        completes = []

        subject = BehaviorSubject(0)

        subscription1 = subscribe!(
            subject,
            lambda(
                on_next = (d) -> push!(values, d),
                on_error = (d) -> push!(errors, d),
                on_complete = () -> push!(completes, 0),
            ),
        )

        @test values == [0]
        @test errors == []
        @test completes == []

        subscription2 = subscribe!(
            subject |> map(Int, d -> d + 1) |> discontinue(),
            lambda(
                on_next = (d) -> next!(subject, d),
                on_error = (e) -> error!(subject, e),
                on_complete = () -> complete!(subject),
            ),
        )

        @test values == [0, 1]
        @test errors == []
        @test completes == []

        error!(subject, "err")

        @test values == [0, 1]
        @test errors == ["err"]
        @test completes == []
    end

    @testset begin
        values = []
        errors = []
        completes = []

        subject = BehaviorSubject(0)

        subscription1 = subscribe!(
            subject,
            lambda(
                on_next = (d) -> push!(values, d),
                on_error = (d) -> push!(errors, d),
                on_complete = () -> push!(completes, 0),
            ),
        )

        @test values == [0]
        @test errors == []
        @test completes == []

        subscription2 = subscribe!(
            subject |> map(Int, d -> d + 1) |> discontinue(),
            lambda(
                on_next = (d) -> next!(subject, d),
                on_error = (e) -> error!(subject, e),
                on_complete = () -> complete!(subject),
            ),
        )

        @test values == [0, 1]
        @test errors == []
        @test completes == []

        complete!(subject)

        @test values == [0, 1]
        @test errors == []
        @test completes == [0]
    end

end

end
