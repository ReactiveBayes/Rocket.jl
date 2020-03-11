module RocketTakeUntilOperatorTest

using Test
using Rocket

@testset "operator: take_until()" begin

    @testset begin
        source = from(1:5) |> take_until(of(1))
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ 1, 2, 3, 4, 5 ]
    end

    @testset begin
        source = interval(1) |> take_until(of(1))
        actor  = keep(Int)
        synced = sync(actor)

        subscribe!(source, synced)

        wait(synced)

        @test actor.values == [ ]
    end

    @testset begin
        source = interval(1) |> take_until(timer(10))
        actor  = keep(Int)
        synced = sync(actor)

        subscribe!(source, synced)

        wait(synced)

        @test maximum(actor.values) < 10
    end

    @testset begin
        source = completed(Int) |> take_until(timer(100))
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ ]
    end

end

end
