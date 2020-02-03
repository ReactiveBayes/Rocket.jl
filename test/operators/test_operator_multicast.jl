module RocketNoopOperatorTest

using Test
using Rocket

@testset "operator: multicast()" begin

    @testset begin
        subject = make_subject(Int, mode = SYNCHRONOUS_SUBJECT_MODE)
        source  = from(1:5) |> multicast(subject)

        actor1 = keep(Int)
        actor2 = keep(Int)

        subscription1 = subscribe!(source, actor1)
        subscription2 = subscribe!(source, actor2)

        @test actor1.values == []
        @test actor2.values == []

        connect(source)

        @test actor1.values == [ 1, 2, 3, 4, 5 ]
        @test actor2.values == [ 1, 2, 3, 4, 5 ]
    end

end

end
