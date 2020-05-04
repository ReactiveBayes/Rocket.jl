module RocketReplaySubjectTest

using Test
using Rocket

@testset "ReplaySubject" begin

    @testset begin
        subject = ReplaySubject(Int, 2)

        actor1 = keep(Int)
        actor2 = keep(Int)

        next!(subject, -2);
        next!(subject, -1);

        subscription1 = subscribe!(subject, actor1)

        next!(subject, 0);
        next!(subject, 1);

        subscription2 = subscribe!(subject, actor2)

        next!(subject, 3);
        next!(subject, 4);

        unsubscribe!(subscription1);

        next!(subject, 5);
        next!(subject, 6);

        unsubscribe!(subscription2);

        @test actor1.values == [ -2, -1, 0, 1, 3, 4 ]
        @test actor2.values == [  0,  1, 3, 4, 5, 6 ]
    end

    @testset begin
        subject = ReplaySubject(Int, 2)

        actor1 = keep(Int)
        actor2 = keep(Int)

        values = Int[]
        source = from(1:5) |> tap(d -> push!(values, d))

        subscription1 = subscribe!(subject, actor1)
        subscription2 = subscribe!(subject, actor2)

        subscribe!(source, subject)

        @test values        == [ 1, 2, 3, 4, 5 ]
        @test actor1.values == [ 1, 2, 3, 4, 5 ]
        @test actor2.values == [ 1, 2, 3, 4, 5 ]

        actor3 = keep(Int)

        subscription3 = subscribe!(subject, actor3)

        @test actor3.values == [ 4, 5 ]

        unsubscribe!(subscription1)
        unsubscribe!(subscription2)
        unsubscribe!(subscription3)
    end

    @testset begin
        subject_factory = ReplaySubjectFactory(2)
        subject = create_subject(Int, subject_factory)

        actor1 = keep(Int)
        actor2 = keep(Int)

        values = Int[]
        source = from(1:5) |> tap(d -> push!(values, d))

        subscription1 = subscribe!(subject, actor1)
        subscription2 = subscribe!(subject, actor2)

        subscribe!(source, subject)

        @test values        == [ 1, 2, 3, 4, 5 ]
        @test actor1.values == [ 1, 2, 3, 4, 5 ]
        @test actor2.values == [ 1, 2, 3, 4, 5 ]

        actor3 = keep(Int)

        subscription3 = subscribe!(subject, actor3)

        @test actor3.values == [ 4, 5 ]

        unsubscribe!(subscription1)
        unsubscribe!(subscription2)
    end

end

end
