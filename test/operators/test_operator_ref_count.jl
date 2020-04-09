module RocketRefCountOperatorTest

using Test
using Rocket

include("../test_helpers.jl")

@testset "operator: ref_count()" begin

    run_proxyshowcheck("RefCount", ref_count(), args = (custom_source = Rocket.connectable(make_subject(Any), never(Any)), check_subscription = true, ))

    @testset begin
        subject = make_subject(Int, mode = SYNCHRONOUS_SUBJECT_MODE)
        source  = from(1:5) |> multicast(subject) |> ref_count()

        actor1 = keep(Int)
        actor2 = keep(Int)

        subscription1 = subscribe!(source, actor1)
        subscription2 = subscribe!(source, actor2)

        unsubscribe!(subscription1)
        unsubscribe!(subscription2)

        @test actor1.values == [ 1, 2, 3, 4, 5 ]
        @test actor2.values == [ ]
    end

end

end
