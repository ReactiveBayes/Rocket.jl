module RxFirstOperatorTest

using Test
using Rx

@testset "operator: first()" begin

    @testset begin
        source = from(1:42) |> first()
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ 1 ]
    end

    @testset begin
        source = interval(1) |> first()
        actor  = keep(Int)
        synced = sync(actor)

        subscribe!(source, synced)

        wait(synced)

        @test actor.values == [ 0 ]
    end

    @testset begin
        source = completed(Int) |> first()
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ ]
    end

end

end
