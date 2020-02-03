module RocketCombineLatestObservableTest

using Test
using Rocket

@testset "CombineLatestObservable" begin

    @testset begin
        @test_throws ErrorException combineLatest()
    end

    @testset begin
        latest = combineLatest(of(1), from(1:5))
        actor  = keep(Tuple{Int, Int})
        subscribe!(latest, actor)
        @test actor.values == [ (1, 1), (1, 2), (1, 3), (1, 4), (1, 5) ]
    end

    @testset begin
        latest = combineLatest(from(1:5), of(2))
        actor  = keep(Tuple{Int, Int})
        subscribe!(latest, actor)
        @test actor.values == [ (5, 2) ]
    end

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

end

end
