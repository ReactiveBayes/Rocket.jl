module RocketLastOperatorTest

using Test
using Rocket

@testset "operator: last()" begin

    @testset begin
        source = from(1:42) |> last()
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ 42 ]
    end

    @testset begin
        source = interval(1) |> take(10) |> last()
        actor  = keep(Int)
        synced = sync(actor)

        subscribe!(source, synced)

        wait(synced)

        @test actor.values == [ 9 ]
    end

    @testset begin
        source = completed(Int) |> last()
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ ]
    end

end

end
