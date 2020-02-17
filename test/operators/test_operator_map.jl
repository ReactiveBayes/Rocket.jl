module RocketMapOperatorTest

using Test
using Rocket

@testset "operator: map()" begin

    @testset begin
        source = from(1:5) |> map(Int, d -> d ^ 2)
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ 1, 4, 9, 16, 25 ]
    end

    @testset begin
        source = timer(1, 1) |> take(5) |> map(Int, d -> d ^ 2)
        actor  = keep(Int)
        synced = sync(actor)

        subscribe!(source, synced)

        wait(synced)

        @test actor.values == [ 0, 1, 4, 9, 16 ]
    end

end

end
