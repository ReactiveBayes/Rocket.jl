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

    @CreateMapOperator(Squared, Int, Int, d -> d ^ 2)

    @testset begin
        source = from(1:5) |> SquaredMapOperator()
        actor  = keep(Int)

        subscribe!(source, actor)

        @test actor.values == [ 1, 4, 9, 16, 25 ]
    end

    @CreateMapOperator(Identity, d -> d)

    @testset begin
        source1 = from(1:5) |> IdentityMapOperator{Int, Int}()
        actor1  = keep(Int)

        subscribe!(source1, actor1)

        @test actor1.values == [ 1, 2, 3, 4, 5 ]

        source2 = from([ "H", "e" ]) |> IdentityMapOperator{String, String}()
        actor2  = keep(String)

        subscribe!(source2, actor2)

        @test actor2.values == [ "H", "e" ]
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
