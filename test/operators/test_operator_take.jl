module RxTakeOperatorTest

using Test
using Rx

@testset "operator: take()" begin

    @testset begin
        source = from(1:42) |> take(3)
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ 1, 2, 3 ]
    end

    @testset begin
        source = interval(1) |> take(5)
        actor  = keep(Int)
        synced = sync(actor)

        subscribe!(source, synced)

        wait(synced)

        @test actor.values == [ 0, 1, 2, 3, 4 ]
    end

    @testset begin
        source = completed(Int) |> take(10)
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ ]
    end

end

end
