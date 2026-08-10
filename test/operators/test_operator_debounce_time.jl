module RocketDebounceTimeOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: debounce_time()" begin

    println("Testing: operator debounce_time()")

    run_proxyshowcheck(
        "DebounceTime",
        debounce_time(10);
        args = (check_subscription = true,),
    )

    @testset "emits the last value after the quiet period (issue #80)" begin
        source = Subject(Int)
        values = Int[]
        subscription =
            subscribe!(source |> debounce_time(50), lambda(on_next = v -> push!(values, v)))

        next!(source, 1)
        next!(source, 2)   # arrives within the window and restarts it

        sleep(0.3)         # let the quiet period elapse and the timer fire

        @test values == [2]

        unsubscribe!(subscription)
    end

    @testset "flushes a pending value on completion (issue #80)" begin
        source = Subject(Int)
        values = Int[]
        completed = Ref(false)
        subscribe!(
            source |> debounce_time(50),
            lambda(
                on_next = v -> push!(values, v),
                on_complete = () -> (completed[] = true),
            ),
        )

        next!(source, 7)
        complete!(source)   # must flush the pending 7 before completing

        @test values == [7]
        @test completed[] == true
    end

    @testset "values separated by more than the quiet period are all emitted" begin
        source = Subject(Int)
        values = Int[]
        subscription =
            subscribe!(source |> debounce_time(20), lambda(on_next = v -> push!(values, v)))

        next!(source, 1)
        sleep(0.15)   # exceeds the quiet period -> 1 is flushed
        next!(source, 2)
        sleep(0.15)   # -> 2 is flushed

        @test values == [1, 2]

        unsubscribe!(subscription)
    end

end

end
