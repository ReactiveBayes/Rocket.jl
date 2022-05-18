module RocketTakeOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: take()" begin

    println("Testing: operator take()")

    run_proxyshowcheck("Take", take(1))

    run_testset([
        (
            source = from(1:5) |> take(3),
            values = @ts([ 1:3, c ])
        ),
        (
            source = from(1:5) |> take(0),
            values = @ts(c)
        ),
        (
            source = from(1:5) |> async(0) |> take(3),
            values = @ts([ 1 ] ~ [ 2 ] ~ [ 3, c ])
        ),
        (
            source = timer(100, 30) |> take(3),
            values = @ts(100 ~ [ 0 ] ~ 30 ~ [ 1 ] ~ 30 ~ [ 2, c ])
        ),
        (
            source = completed() |> take(10),
            values = @ts(c)
        ),
        (
            source = faulted("e") |> take(10),
            values = @ts(e("e"))
        ),
        (
            source = never() |> take(10),
            values = @ts()
        )
    ])

    @testset "Infinite reaction" begin 
        source = Subject(Int)
        events = []

        subscription = subscribe!(source |> take(3), lambda(
            on_next     = (state) -> begin 
                push!(events, state)
                next!(source, state + 1)
            end,
            on_complete = () -> push!(events, "c")
        ))

        next!(source, 1)

        @test events == [ 1, 2, 3, "c" ]
    end

end

end
