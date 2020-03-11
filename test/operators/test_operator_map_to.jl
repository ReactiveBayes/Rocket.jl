module RocketMapToOperatorTest

using Test
using Rocket

@testset "operator: map_to()" begin

    @testset begin
        source = from(1:5) |> map_to('a')
        actor  = keep(Char)

        subscribe!(source, actor)

        @test actor.values == [ 'a', 'a', 'a', 'a', 'a' ]
    end

    @testset begin
        source = timer(1, 1) |> take(5) |> map_to(1)
        actor  = keep(Int)
        synced = sync(actor)

        subscribe!(source, synced)

        wait(synced)

        @test actor.values == [ 1, 1, 1, 1, 1 ]
    end

end

end