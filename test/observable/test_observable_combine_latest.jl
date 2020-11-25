module RocketCombineLatestObservableTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "CombineLatestObservable" begin

    println("Testing: combineLatest")

    @testset begin
        @test_throws ErrorException combineLatest()
    end

    run_testset([
        (
            source = combineLatest(of(1), from(1:5)),
            values = @ts([ (1, 1), (1, 2), (1, 3), (1, 4), (1, 5), c ]),
            source_type = Tuple{Int, Int}
        ),
        (
            source = combineLatest(of(1) |> async(0), from(1:5)),
            values = @ts([ (1, 5) ] ~ c),
            source_type = Tuple{Int, Int}
        ),
        (
            source = combineLatest(of(1) |> async(0), from(1:5) |> async(0)),
            values = @ts([ (1, 1) ] ~ [ (1, 2) ] ~ [ (1, 3) ] ~ [ (1, 4) ] ~ [ (1, 5) ] ~ c),
            source_type = Tuple{Int, Int}
        ),
        (
            source = combineLatest(from(1:5), of(2.0)),
            values = @ts([ (5, 2), c ]),
            source_type = Tuple{Int, Float64}
        ),
        (
            source = combineLatest(from(1:5) |> async(0), of(2.0)),
            values = @ts([ (1, 2.0) ] ~ [ (2, 2.0) ] ~ [ (3, 2.0) ] ~ [ (4, 2.0) ] ~ [ (5, 2.0) ] ~ c),
            source_type = Tuple{Int, Float64}
        ),
        (
            source = combineLatest(completed(Int), of(1)),
            values = @ts(c),
            source_type = Tuple{Int, Int}
        ),
        (
            source = combineLatest(completed(Int), completed(Int)),
            values = @ts(c),
            source_type = Tuple{Int, Int}
        ),
        (
            source = combineLatest(faulted(Float64, "err"), completed(Int)),
            values = @ts(e("err")),
            source_type = Tuple{Float64, Int}
        ),
        (
            source = combineLatest(completed(Int), faulted(Float64, "err")),
            values = @ts(c),
            source_type = Tuple{Int, Float64}
        ),
        (
            source = combineLatest(faulted(Float64, "err1"), faulted(Float64, "err2")),
            values = @ts(e("err1")),
            source_type = Tuple{Float64, Float64}
        ),
        (
            source = combineLatest(of(1), from(1:5), strategy = PushNew()),
            values = @ts([ (1, 1), (1, 2), (1, 3), (1, 4), (1, 5), c ]),
            source_type = Tuple{Int, Int}
        ),
        (
            source = combineLatest(of(1) |> async(0), from(1:5), strategy = PushNew()),
            values = @ts([ (1, 5) ] ~ c),
            source_type = Tuple{Int, Int}
        ),
        (
            source = combineLatest(from(1:5), of(2.0), strategy = PushNew()),
            values = @ts([ (5, 2), c ]),
            source_type = Tuple{Int, Float64}
        ),
        (
            source = combineLatest(from(1:5) |> async(0), of(2.0), strategy = PushNew()),
            values = @ts([ (1, 2.0) ] ~ [ (2, 2.0) ] ~ [ (3, 2.0) ] ~ [ (4, 2.0) ] ~ [ (5, 2.0) ] ~ c),
            source_type = Tuple{Int, Float64}
        ),
        (
            source = combineLatest(completed(Int), of(1), strategy = PushNew()),
            values = @ts(c),
            source_type = Tuple{Int, Int}
        ),
        (
            source = combineLatest(completed(Int), completed(Int), strategy = PushNew()),
            values = @ts(c),
            source_type = Tuple{Int, Int}
        ),
        (
            source = combineLatest(faulted(Float64, "err"), completed(Int), strategy = PushNew()),
            values = @ts(e("err")),
            source_type = Tuple{Float64, Int}
        ),
        (
            source = combineLatest(completed(Int), faulted(Float64, "err"), strategy = PushNew()),
            values = @ts(c),
            source_type = Tuple{Int, Float64}
        ),
        (
            source = combineLatest(faulted(Float64, "err1"), faulted(Float64, "err2"), strategy = PushNew()),
            values = @ts(e("err1")),
            source_type = Tuple{Float64, Float64}
        ),
    ])

    somenumbers    = [ [ 1 for i in 1:50 ]..., [ 1.0 for i in 1:50 ]... ]
    expectedoutput = tuple(somenumbers...)

    combined100 = combineLatest(map(n -> of(n), somenumbers)...)

    run_testset([
        (
            source = combined100,
            values = @ts([ tuple([ [ 1 for i in 1:50 ]..., [ 1.0 for i in 1:50 ]... ]...), c ]),
            source_type = Tuple{ map(n -> typeof(n), somenumbers)... }
        )
    ])


    @testset begin
        s1 = Subject(Int)
        s2 = Subject(Float64)
        s3 = Subject(String)
        s4 = of(5)
        s5 = from(1:10)

        latest = combineLatest(s1, s2, s3, s4, s5)
        values = Vector{Any}()
        subscription = subscribe!(latest, lambda(
            on_next     = (d) -> push!(values, d),
            on_error    = (e) -> push!(values, e),
            on_complete = ()  -> push!(values, "completed")
        ))

        @test values == [ ]

        next!(s1, 1)

        @test values == [ ]

        next!(s2, 2.0)

        @test values == [ ]

        next!(s3, "Hello")

        @test values == [ (1, 2.0, "Hello", 5, 10) ]

        next!(s1, 2)

        @test values == [ (1, 2.0, "Hello", 5, 10), (2, 2.0, "Hello", 5, 10) ]

        next!(s3, "Hello, world!")

        @test values == [ (1, 2.0, "Hello", 5, 10), (2, 2.0, "Hello", 5, 10), (2, 2.0, "Hello, world!", 5, 10)  ]

        complete!(s1);

        next!(s2, 3.0)

        @test values == [ (1, 2.0, "Hello", 5, 10), (2, 2.0, "Hello", 5, 10), (2, 2.0, "Hello, world!", 5, 10), (2, 3.0, "Hello, world!", 5, 10)  ]

        complete!(s2)

        @test values == [ (1, 2.0, "Hello", 5, 10), (2, 2.0, "Hello", 5, 10), (2, 2.0, "Hello, world!", 5, 10), (2, 3.0, "Hello, world!", 5, 10)  ]

        unsubscribe!(subscription)
    end

    @testset begin
        s1 = Subject(Int)
        s2 = Subject(Float64)
        s3 = Subject(String)
        s4 = of(5)
        s5 = from(1:10)

        latest = combineLatest(s1, s2, s3, s4, s5, strategy = PushNew())
        values = Vector{Any}()
        subscription = subscribe!(latest, lambda(
            on_next     = (d) -> push!(values, d),
            on_error    = (e) -> push!(values, e),
            on_complete = ()  -> push!(values, "completed")
        ))

        @test values == [ ]

        next!(s1, 1)

        @test values == [ ]

        next!(s2, 2.0)

        @test values == [ ]

        next!(s3, "Hello")

        @test values == [ (1, 2.0, "Hello", 5, 10) ]

        next!(s1, 2)

        @test values == [ (1, 2.0, "Hello", 5, 10) ]

        next!(s3, "Hello, world!")

        @test values == [ (1, 2.0, "Hello", 5, 10)  ]

        complete!(s1);

        next!(s2, 3.0)

        @test values == [ (1, 2.0, "Hello", 5, 10), (2, 3.0, "Hello, world!", 5, 10)  ]

        complete!(s2)

        @test values == [ (1, 2.0, "Hello", 5, 10), (2, 3.0, "Hello, world!", 5, 10)  ]

        next!(s3, "Something")

        @test values == [ (1, 2.0, "Hello", 5, 10), (2, 3.0, "Hello, world!", 5, 10), (2, 3.0, "Something", 5, 10)  ]

        complete!(s3)

        @test values == [ (1, 2.0, "Hello", 5, 10), (2, 3.0, "Hello, world!", 5, 10), (2, 3.0, "Something", 5, 10), "completed"  ]

        unsubscribe!(subscription)
    end

    @testset begin
        s1 = Subject(Int)
        s2 = Subject(Float64)
        s3 = Subject(String)

        latest = combineLatest(s1, s2, s3, strategy = PushNewBut{1}())
        values = Vector{Any}()
        subscription = subscribe!(latest, lambda(
            on_next     = (d) -> push!(values, d),
            on_error    = (e) -> push!(values, e),
            on_complete = ()  -> push!(values, "completed")
        ))

        @test values == [ ]

        next!(s1, 1)

        @test values == [ ]

        next!(s2, 2.0)

        @test values == [ ]

        next!(s3, "Hello")

        @test values == [ (1, 2.0, "Hello") ]

        next!(s2, 3.0)

        @test values == [ (1, 2.0, "Hello") ]

        next!(s3, "Hello, world!")

        @test values == [ (1, 2.0, "Hello"), (1, 3.0, "Hello, world!") ]

        next!(s1, 2)

        @test values == [ (1, 2.0, "Hello"), (1, 3.0, "Hello, world!") ]

        next!(s1, 3)

        @test values == [ (1, 2.0, "Hello"), (1, 3.0, "Hello, world!") ]

        next!(s1, 4)

        @test values == [ (1, 2.0, "Hello"), (1, 3.0, "Hello, world!") ]

        next!(s2, 4.0)

        @test values == [ (1, 2.0, "Hello"), (1, 3.0, "Hello, world!") ]

        next!(s3, "")

        @test values == [ (1, 2.0, "Hello"), (1, 3.0, "Hello, world!"), (4, 4.0, "") ]

        complete!(s1);

        next!(s2, 5.0)

        @test values == [ (1, 2.0, "Hello"), (1, 3.0, "Hello, world!"), (4, 4.0, "") ]

        next!(s3, "foo")

        @test values == [ (1, 2.0, "Hello"), (1, 3.0, "Hello, world!"), (4, 4.0, ""), (4, 5.0, "foo") ]

        complete!(s2)

        @test values == [ (1, 2.0, "Hello"), (1, 3.0, "Hello, world!"), (4, 4.0, ""), (4, 5.0, "foo") ]

        next!(s3, "bar")

        @test values == [ (1, 2.0, "Hello"), (1, 3.0, "Hello, world!"), (4, 4.0, ""), (4, 5.0, "foo"), (4, 5.0, "bar") ]

        complete!(s3)

        @test values == [ (1, 2.0, "Hello"), (1, 3.0, "Hello, world!"), (4, 4.0, ""), (4, 5.0, "foo"), (4, 5.0, "bar"), "completed" ]

        unsubscribe!(subscription)
    end

    @testset begin
        s1 = Subject(Int)
        s2 = Subject(Float64)
        s3 = Subject(String)

        latest = combineLatest(s1, s2, s3, strategy = PushStrategy(BitArray([ false, true, false ])))
        values = Vector{Any}()
        subscription = subscribe!(latest, lambda(
            on_next     = (d) -> push!(values, d),
            on_error    = (e) -> push!(values, e),
            on_complete = ()  -> push!(values, "completed")
        ))

        @test values == [ ]

        next!(s1, 1)

        @test values == [ ]

        next!(s2, 2.0)

        @test values == [ ]

        next!(s3, "Hello")

        @test values == [ (1, 2.0, "Hello") ]

        next!(s2, 3.0)

        @test values == [ (1, 2.0, "Hello") ]

        next!(s3, "Hello, world!")

        @test values == [ (1, 2.0, "Hello") ]

        next!(s1, 2)

        @test values == [ (1, 2.0, "Hello"), (2, 3.0, "Hello, world!") ]

        next!(s1, 3)

        @test values == [ (1, 2.0, "Hello"), (2, 3.0, "Hello, world!") ]

        next!(s1, 4)

        @test values == [ (1, 2.0, "Hello"), (2, 3.0, "Hello, world!") ]

        next!(s2, 4.0)

        @test values == [ (1, 2.0, "Hello"), (2, 3.0, "Hello, world!") ]

        next!(s3, "")

        @test values == [ (1, 2.0, "Hello"), (2, 3.0, "Hello, world!"), (4, 4.0, "") ]

        complete!(s1);

        @test values == [ (1, 2.0, "Hello"), (2, 3.0, "Hello, world!"), (4, 4.0, "") ]

        next!(s2, 5.0)

        @test values == [ (1, 2.0, "Hello"), (2, 3.0, "Hello, world!"), (4, 4.0, "") ]

        next!(s3, "1")

        @test values == [ (1, 2.0, "Hello"), (2, 3.0, "Hello, world!"), (4, 4.0, ""), (4, 5.0, "1") ]

        complete!(s3)

        @test values == [ (1, 2.0, "Hello"), (2, 3.0, "Hello, world!"), (4, 4.0, ""), (4, 5.0, "1") ]

        next!(s2, 6.0)

        @test values == [ (1, 2.0, "Hello"), (2, 3.0, "Hello, world!"), (4, 4.0, ""), (4, 5.0, "1"), (4, 6.0, "1") ]

        complete!(s2)

        @test values == [ (1, 2.0, "Hello"), (2, 3.0, "Hello, world!"), (4, 4.0, ""), (4, 5.0, "1"), (4, 6.0, "1"), "completed" ]

        unsubscribe!(subscription)
    end

end

end
