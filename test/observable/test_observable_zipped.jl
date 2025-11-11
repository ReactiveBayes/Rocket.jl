module RocketZipObservableTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "ZipObservable" begin

    println("Testing: zipped")

    @testset begin
        @test_throws ErrorException zipped()
    end

    @testset begin
        source = zipped(of(1), of(0.0))
        io = IOBuffer()

        show(io, source)

        printed = String(take!(io))

        @test occursin("ZipObservable", printed)
        @test occursin(string(eltype(source)), printed)
        @test eltype(source) === Tuple{Int,Float64}
    end

    run_testset([
        (
            source = zipped(of(1), of(0.0)),
            values = @ts([(1, 0.0), c]),
            source_type = Tuple{Int,Float64},
        ),
        (
            source = zipped(completed(Int), of(0.0)),
            values = @ts(c),
            source_type = Tuple{Int,Float64},
        ),
        (
            source = zipped(of(1), completed(Int)),
            values = @ts(c),
            source_type = Tuple{Int,Int},
        ),
        (
            source = zipped(completed(Int), completed(Int)),
            values = @ts(c),
            source_type = Tuple{Int,Int},
        ),
        (source = zipped(faulted("e1"), of(0.0)), values = @ts(e("e1"))),
        (source = zipped(of(1), faulted("e2")), values = @ts(e("e2"))),
        (source = zipped(faulted("e1"), faulted("e2")), values = @ts(e("e1"))),
        (source = zipped(never(), of(0.0)), values = @ts()),
        (source = zipped(of(1), never()), values = @ts()),
        (source = zipped(never(), never()), values = @ts()),
        (
            source = zipped(from(1:2), from(1:5)),
            values = @ts([(1, 1), (2, 2), c]),
            source_type = Tuple{Int,Int},
        ),
        (
            source = zipped(from(1:2) |> async(0), from(1:5)),
            values = @ts([(1, 1)] ~ [(2, 2)] ~ c),
            source_type = Tuple{Int,Int},
        ),
        (
            source = zipped(from(1:2), from(1:5) |> async(0)),
            values = @ts([(1, 1)] ~ [(2, 2), c]),
            source_type = Tuple{Int,Int},
        ),
        (
            source = zipped(from(1:2) |> async(0), from(1:5) |> async(0)),
            values = @ts([(1, 1)] ~ [(2, 2), c]),
            source_type = Tuple{Int,Int},
        ),
        (
            source = zipped(from(1:2), from(1:5), of('c')),
            values = @ts([(1, 1, 'c'), c]),
            source_type = Tuple{Int,Int,Char},
        ),
        (
            source = zipped(from(1:2), from(1:2)),
            values = @ts([(1, 1), (2, 2), c]),
            source_type = Tuple{Int,Int},
        ),
        (
            source = zipped(from(1:3), from(1:3) |> ignore(1), from(1:3) |> ignore(2)),
            values = @ts([(1, 2, 3), c]),
            source_type = Tuple{Int,Int,Int},
        ),
    ])

    @testset begin
        s1 = Subject(Int)
        s2 = Subject(Float64)
        s3 = Subject(String)

        latest = zipped(s1, s2, s3)
        values = Vector{Any}()
        subscription = subscribe!(
            latest,
            lambda(
                on_next = (d) -> push!(values, d),
                on_error = (e) -> push!(values, e),
                on_complete = () -> push!(values, "completed"),
            ),
        )

        @test values == []

        next!(s1, 1)

        @test values == []

        next!(s2, 2.0)

        @test values == []

        next!(s3, "Hello")

        @test values == [(1, 2.0, "Hello")]

        next!(s2, 3.0)

        @test values == [(1, 2.0, "Hello")]

        next!(s3, "Hello, world!")

        @test values == [(1, 2.0, "Hello")]

        next!(s1, 2)

        @test values == [(1, 2.0, "Hello"), (2, 3.0, "Hello, world!")]

        next!(s1, 3)

        @test values == [(1, 2.0, "Hello"), (2, 3.0, "Hello, world!")]

        next!(s1, 4)

        @test values == [(1, 2.0, "Hello"), (2, 3.0, "Hello, world!")]

        next!(s2, 4.0)

        @test values == [(1, 2.0, "Hello"), (2, 3.0, "Hello, world!")]

        next!(s3, "")

        @test values == [(1, 2.0, "Hello"), (2, 3.0, "Hello, world!"), (3, 4.0, "")]

        complete!(s1);

        @test values == [(1, 2.0, "Hello"), (2, 3.0, "Hello, world!"), (3, 4.0, "")]

        next!(s2, 5.0)

        @test values == [(1, 2.0, "Hello"), (2, 3.0, "Hello, world!"), (3, 4.0, "")]

        complete!(s2)

        @test values == [(1, 2.0, "Hello"), (2, 3.0, "Hello, world!"), (3, 4.0, "")]

        next!(s3, "last")

        @test values == [
            (1, 2.0, "Hello"),
            (2, 3.0, "Hello, world!"),
            (3, 4.0, ""),
            (4, 5.0, "last"),
            "completed",
        ]

        unsubscribe!(subscription)
    end

end

end
