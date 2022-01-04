module RocketSubjectInstanceTest

using Test
using Rocket

@testset "Subject" begin

    println("Testing: Subject")

    @testset begin
        subject1 = Subject(Int)
        @test eltype(subject1) === Int

        subject2 = Subject(Float64)
        @test eltype(subject2) === Float64
    end

    @testset begin
        subject = Subject(Int)

        actor1 = keep(Int)
        actor2 = keep(Int)

        subscription1 = subscribe!(subject, actor1)

        next!(subject, 0)
        next!(subject, 1)

        subscription2 = subscribe!(subject, actor2)

        next!(subject, 3)
        next!(subject, 4)

        unsubscribe!(subscription1)

        next!(subject, 5)
        next!(subject, 6)

        complete!(subject)

        unsubscribe!(subscription2)

        @test actor1.values == [ 0, 1, 3, 4 ]
        @test actor2.values == [ 3, 4, 5, 6 ]
    end

    @testset begin
        subject = Subject(Int)

        actor1 = keep(Int)
        actor2 = keep(Int)

        values = Int[]
        source = from_iterable(1:5) |> tap(d -> push!(values, d))

        subscription1 = subscribe!(subject, actor1)
        subscription2 = subscribe!(subject, actor2)

        subscribe!(source, subject)

        complete!(subject)

        @test values        == [ 1, 2, 3, 4, 5 ]
        @test actor1.values == [ 1, 2, 3, 4, 5 ]
        @test actor2.values == [ 1, 2, 3, 4, 5 ]

        unsubscribe!(subscription1)
        unsubscribe!(subscription2)
    end

    @testset begin
        subject = Subject(Int)

        values      = []
        errors      = []
        completions = []

        actor = lambda(
            on_next     = (d) -> push!(values, d),
            on_error    = (e) -> push!(errors, e),
            on_complete = ()  -> push!(completions, 0)
        )

        subscribe!(subject, actor)

        @test values      == [ ]
        @test errors      == [ ]
        @test completions == [ ]

        error!(subject, "err")

        @test values      == [ ]
        @test errors      == [ "err" ]
        @test completions == [ ]

        subscribe!(subject, actor)

        @test values      == [ ]
        @test errors      == [ "err", "err" ]
        @test completions == [ ]

    end

    @testset begin
        subject_factory = SubjectFactory(AsapScheduler())
        subject = create_subject(Int, subject_factory)

        actor1 = keep(Int)
        actor2 = keep(Int)

        values = Int[]
        source = from_iterable(1:5) |> tap(d -> push!(values, d))

        subscription1 = subscribe!(subject, actor1)
        subscription2 = subscribe!(subject, actor2)

        subscribe!(source, subject)

        complete!(subject)

        @test values        == [ 1, 2, 3, 4, 5 ]
        @test actor1.values == [ 1, 2, 3, 4, 5 ]
        @test actor2.values == [ 1, 2, 3, 4, 5 ]

        unsubscribe!(subscription1)
        unsubscribe!(subscription2)
    end

    @testset begin
        subject1 = Subject(Int)
        subject2 = similar(subject1)

        @test subject1 !== subject2
        @test typeof(subject2) <: Subject
        @test eltype(subject2) === Int

        actor1 = keep(Int)
        actor2 = keep(Int)

        subscription1 = subscribe!(subject1, actor1)
        subscription2 = subscribe!(subject2, actor2)

        @test subscription1 !== subscription2

        next!(subject1, 1)

        @test actor1.values == [ 1 ]
        @test actor2.values == [  ]

        next!(subject2, 2)

        @test actor1.values == [ 1 ]
        @test actor2.values == [ 2 ]

        unsubscribe!(subscription1)
        unsubscribe!(subscription2)
    end

    @testset begin
        subject = Subject(Int)

        limited = subject |> take(1)

        actor1 = keep(Int)
        actor2 = keep(Int)

        subscription1 = subscribe!(limited, actor1)
        subscription2 = subscribe!(subject, actor2)

        next!(subject, 1)

        @test actor1.values == [ 1 ]
        @test actor2.values == [ 1 ]

        next!(subject, 2)

        @test actor1.values == [ 1 ]
        @test actor2.values == [ 1, 2 ]
    end

    @testset begin

        main = Subject(Int)

        listener1 = Subject(Int)
        listener2 = Subject(Int)
        listener3 = Subject(Int)

        keep1 = keep(Int)
        keep2 = keep(Int)
        keep3 = keep(Int)

        k1 = subscribe!(listener1, keep1)
        k2 = subscribe!(listener2, keep2)
        k3 = subscribe!(listener3, keep3)

        sub1 = subscribe!(main, listener1)
        sub2 = subscribe!(main, listener2)
        sub3 = subscribe!(main, listener3)

        next!(main, 1)

        @test keep1.values == [ 1 ]
        @test keep2.values == [ 1 ]
        @test keep3.values == [ 1 ]

        unsubscribe!(sub2)

        next!(main, 2)

        @test keep1.values == [ 1, 2 ]
        @test keep2.values == [ 1 ]
        @test keep3.values == [ 1, 2 ]

        unsubscribe!(sub3)

        next!(main, 3)

        @test keep1.values == [ 1, 2, 3 ]
        @test keep2.values == [ 1 ]
        @test keep3.values == [ 1, 2 ]

        unsubscribe!(sub2) # sub2 here is intentional

        next!(main, 4)

        @test keep1.values == [ 1, 2, 3, 4 ]
        @test keep2.values == [ 1 ]
        @test keep3.values == [ 1, 2 ]
    end

end

end
