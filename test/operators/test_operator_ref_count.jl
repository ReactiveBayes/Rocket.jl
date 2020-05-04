module RocketRefCountOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: ref_count()" begin

    println("Testing: operator ref_count()")

    run_proxyshowcheck("RefCount", ref_count(), args = (custom_source = Rocket.connectable(Subject(Any), never(Any)), check_subscription = true, ))

    @testset begin
        source  = from(1:5) |> multicast(Subject(Int)) |> ref_count()

        actor1 = keep(Int)
        actor2 = keep(Int)

        subscription1 = subscribe!(source, actor1)
        subscription2 = subscribe!(source, actor2)

        unsubscribe!(subscription1)
        unsubscribe!(subscription2)

        @test actor1.values == [ 1, 2, 3, 4, 5 ]
        @test actor2.values == [ ]
    end

    @testset begin
        subject = Subject(Int)
        source  = subject |> multicast(Subject(Int)) |> ref_count()

        actor1 = keep(Int)
        actor2 = keep(Int)
        actor3 = keep(Int)

        subscription3 = subscribe!(subject, actor3)

        next!(subject, 1)

        @test actor1.values == [ ]
        @test actor2.values == [ ]
        @test actor3.values == [ 1 ]

        subscription1 = subscribe!(source, actor1)
        subscription2 = subscribe!(source, actor2)

        @test actor1.values == [ ]
        @test actor2.values == [ ]
        @test actor3.values == [ 1 ]

        next!(subject, 2)

        @test actor1.values == [ 2 ]
        @test actor2.values == [ 2 ]
        @test actor3.values == [ 1, 2 ]

        unsubscribe!(subscription1)

        next!(subject, 3)

        @test actor1.values == [ 2 ]
        @test actor2.values == [ 2, 3 ]
        @test actor3.values == [ 1, 2, 3 ]

        unsubscribe!(subscription2)
        subscription1 = subscribe!(source, actor1)

        next!(subject, 4)

        @test actor1.values == [ 2, 4 ]
        @test actor2.values == [ 2, 3 ]
        @test actor3.values == [ 1, 2, 3, 4 ]

        unsubscribe!(subscription1)
        unsubscribe!(subscription2)

        next!(subject, 5)

        @test actor1.values == [ 2, 4 ]
        @test actor2.values == [ 2, 3 ]
        @test actor3.values == [ 1, 2, 3, 4, 5]
    end

end

end
