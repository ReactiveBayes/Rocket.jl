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
        source = from(1:5) |> tap(d -> push!(values, d))

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
        source = from(1:5) |> tap(d -> push!(values, d))

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

end

end
