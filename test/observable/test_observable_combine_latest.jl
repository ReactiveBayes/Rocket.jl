module RocketCombineLatestObservableTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "CombineLatestObservable" begin

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
            source = combineLatest(of(1) |> async(), from(1:5)),
            values = @ts([ (1, 5) ] ~ c),
            source_type = Tuple{Int, Int}
        ),
        (
            source = combineLatest(from(1:5), of(2.0)),
            values = @ts([ (5, 2), c ]),
            source_type = Tuple{Int, Float64}
        ),
        (
            source = combineLatest(from(1:5) |> async(), of(2.0)),
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
            source = combineLatest(throwError("err", Float64), completed(Int)),
            values = @ts(e("err")),
            source_type = Tuple{Float64, Int}
        ),
        (
            source = combineLatest(completed(Int), throwError("err", Float64)),
            values = @ts(c),
            source_type = Tuple{Int, Float64}
        ),
        (
            source = combineLatest(throwError("err1", Float64), throwError("err2", Float64)),
            values = @ts(e("err1")),
            source_type = Tuple{Float64, Float64}
        ),
        (
            source = combineLatest(of(1), of(2), transformType = Int, transformFn = (t) -> t[1]^2 + t[2]^2),
            values = @ts([ 5, c ]),
            source_type = Int
        ),
        (
            source = combineLatest(of(1), from(1:5), isbatch = true),
            values = @ts([ (1, 1), (1, 2), (1, 3), (1, 4), (1, 5), c ]),
            source_type = Tuple{Int, Int}
        ),
        (
            source = combineLatest(of(1) |> async(), from(1:5), isbatch = true),
            values = @ts([ (1, 5) ] ~ c),
            source_type = Tuple{Int, Int}
        ),
        (
            source = combineLatest(from(1:5), of(2.0), isbatch = true),
            values = @ts([ (5, 2), c ]),
            source_type = Tuple{Int, Float64}
        ),
        (
            source = combineLatest(from(1:5) |> async(), of(2.0), isbatch = true),
            values = @ts([ (1, 2.0) ] ~ [ (2, 2.0) ] ~ [ (3, 2.0) ] ~ [ (4, 2.0) ] ~ [ (5, 2.0) ] ~ c),
            source_type = Tuple{Int, Float64}
        ),
        (
            source = combineLatest(completed(Int), of(1), isbatch = true),
            values = @ts(c),
            source_type = Tuple{Int, Int}
        ),
        (
            source = combineLatest(completed(Int), completed(Int), isbatch = true),
            values = @ts(c),
            source_type = Tuple{Int, Int}
        ),
        (
            source = combineLatest(throwError("err", Float64), completed(Int), isbatch = true),
            values = @ts(e("err")),
            source_type = Tuple{Float64, Int}
        ),
        (
            source = combineLatest(completed(Int), throwError("err", Float64), isbatch = true),
            values = @ts(c),
            source_type = Tuple{Int, Float64}
        ),
        (
            source = combineLatest(throwError("err1", Float64), throwError("err2", Float64), isbatch = true),
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
        s1 = make_subject(Int, mode = SYNCHRONOUS_SUBJECT_MODE)
        s2 = make_subject(Float64, mode = SYNCHRONOUS_SUBJECT_MODE)
        s3 = make_subject(String, mode = SYNCHRONOUS_SUBJECT_MODE)
        s4 = of(5)
        s5 = from(1:10)

        latest = combineLatest(s1, s2, s3, s4, s5)
        actor  = keep(Tuple{Int, Float64, String, Int, Int})
        subscription = subscribe!(latest, actor)

        @test actor.values == [ ]

        next!(s1, 1)

        @test actor.values == [ ]

        next!(s2, 2.0)

        @test actor.values == [ ]

        next!(s3, "Hello")

        @test actor.values == [ (1, 2.0, "Hello", 5, 10) ]

        next!(s1, 2)

        @test actor.values == [ (1, 2.0, "Hello", 5, 10), (2, 2.0, "Hello", 5, 10) ]

        next!(s3, "Hello, world!")

        @test actor.values == [ (1, 2.0, "Hello", 5, 10), (2, 2.0, "Hello", 5, 10), (2, 2.0, "Hello, world!", 5, 10)  ]

        complete!(s1);

        next!(s2, 3.0)

        @test actor.values == [ (1, 2.0, "Hello", 5, 10), (2, 2.0, "Hello", 5, 10), (2, 2.0, "Hello, world!", 5, 10), (2, 3.0, "Hello, world!", 5, 10)  ]

        unsubscribe!(subscription)
    end

    @testset begin
        s1 = make_subject(Int, mode = SYNCHRONOUS_SUBJECT_MODE)
        s2 = make_subject(Float64, mode = SYNCHRONOUS_SUBJECT_MODE)
        s3 = make_subject(String, mode = SYNCHRONOUS_SUBJECT_MODE)
        s4 = of(5)
        s5 = from(1:10)

        latest = combineLatest(s1, s2, s3, s4, s5, isbatch = true)
        actor  = keep(Tuple{Int, Float64, String, Int, Int})
        subscription = subscribe!(latest, actor)

        @test actor.values == [ ]

        next!(s1, 1)

        @test actor.values == [ ]

        next!(s2, 2.0)

        @test actor.values == [ ]

        next!(s3, "Hello")

        @test actor.values == [ (1, 2.0, "Hello", 5, 10) ]

        next!(s1, 2)

        @test actor.values == [ (1, 2.0, "Hello", 5, 10) ]

        next!(s3, "Hello, world!")

        @test actor.values == [ (1, 2.0, "Hello", 5, 10)  ]

        complete!(s1);

        next!(s2, 3.0)

        @test actor.values == [ (1, 2.0, "Hello", 5, 10), (2, 3.0, "Hello, world!", 5, 10)  ]

        unsubscribe!(subscription)
    end

end

end
