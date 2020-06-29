module RocketRaceObservableTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "ConcatObservable" begin

    println("Testing: concat")

    @testset begin
        @test_throws ErrorException concat()
    end

    run_testset([
        (
            source = concat(of(1), from(1:5)),
            values = @ts([ 1, 1, 2, 3, 4, 5, c ]),
            source_type = Int
        ),
        (
            source = concat(of(1.0) |> async(0), from(1:5)),
            values = @ts([ 1 ] ~ [ 1, 2, 3, 4, 5, c ]),
            source_type = Union{Float64, Int}
        ),
        (
            source = concat(completed(Int), of(1)),
            values = @ts([ 1, c ]),
            source_type = Int
        ),
        (
            source = concat(completed(Int), completed(Int)),
            values = @ts(c),
            source_type = Int
        ),
        (
            source = concat(faulted(Float64, "err"), completed(Int)),
            values = @ts(e("err")),
            source_type = Union{Float64, Int}
        ),
        (
            source = concat(completed(Int), faulted(Float64, "err")),
            values = @ts(e("err")),
            source_type = Union{Int, Float64}
        ),
        (
            source = concat(faulted(Float64, "err1"), faulted(Float64, "err2")),
            values = @ts(e("err1")),
            source_type = Float64
        ),
        (
            source = concat(interval(50) |> take(3), of(3)),
            values = @ts([ 0 ] ~ 30 ~ [ 1 ] ~ 30 ~ [ 2, 3, c ] )
        )
    ])

    @testset begin
        s1 = Subject(Int)
        s2 = Subject(Float64)

        source = concat(s1, s2)
        values = Vector{Any}()
        subscription = subscribe!(source, lambda(
            on_next     = (d) -> push!(values, d),
            on_error    = (e) -> push!(values, e),
            on_complete = ()  -> push!(values, "completed")
        ))

        @test eltype(source) === Union{Int, Float64}

        @test values == [ ]

        next!(s1, 1)

        @test values == [ 1 ]

        next!(s2, 2.0)

        @test values == [ 1 ]

        complete!(s2)

        @test values == [ 1 ]

        complete!(s1)

        @test values == [ 1, "completed" ]

        unsubscribe!(subscription)
    end

    @testset begin
        s1 = Subject(Int)
        s2 = Subject(Float64)

        source = concat(s1, s2)
        values = Vector{Any}()
        subscription = subscribe!(source, lambda(
            on_next     = (d) -> push!(values, d),
            on_error    = (e) -> push!(values, e),
            on_complete = ()  -> push!(values, "completed")
        ))

        @test eltype(source) === Union{Int, Float64}

        @test values == [ ]

        next!(s2, 2.0)

        @test values == [ ]

        next!(s1, 1)

        @test values == [ 1 ]

        complete!(s1)

        @test values == [ 1 ]

        next!(s2, 2.0)

        @test values == [ 1, 2.0 ]

        complete!(s2)

        @test values == [ 1, 2.0, "completed" ]

        unsubscribe!(subscription)
    end

    @testset begin
        s1 = Subject(Int)
        s2 = Subject(Float64)

        source = concat(s1, s2)
        values = Vector{Any}()
        subscription = subscribe!(source, lambda(
            on_next     = (d) -> push!(values, d),
            on_error    = (e) -> push!(values, e),
            on_complete = ()  -> push!(values, "completed")
        ))

        @test eltype(source) === Union{Int, Float64}

        @test values == [ ]

        unsubscribe!(subscription)

        next!(s1, 1)

        @test values == [ ]

        next!(s2, 2.0)

        @test values == [ ]

        complete!(s1)

        @test values == [ ]

        complete!(s2)

        @test values == [ ]
    end

end

end
