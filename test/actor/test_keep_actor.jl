module RocketKeepActorTest

using Test
using Rocket

@testset "KeepActor" begin

    println("Testing: actor KeepActor")

    @testset begin
        source = from([ 1, 2, 3 ])
        actor  = KeepActor{Int}()

        subscribe!(source, actor)

        @test actor.values == [ 1, 2, 3 ]
        @test getvalues(actor) == [ 1, 2, 3 ]
    end

    @testset begin
        source = from([ 1, 2, 3 ])
        actor  = KeepActor{Int}()

        subscribe!(source, actor)

        @test actor[1] === 1
        @test actor[2] === 2
        @test actor[3] === 3

        @test collect(actor) == [ 1, 2, 3 ]
    end

    @testset begin
        source = from([ 1, 2, 3 ])
        actor  = KeepActor{Int}()

        subscribe!(source, actor)

        i = 1
        for item in actor
            @test item === i
            i += 1
        end
    end

    @testset begin
        source = from([ 1, 2, 3 ])
        actor  = KeepActor{Int}()

        subscribe!(source, actor)

        @test actor[1:end] == [ 1, 2, 3 ]
    end

    @testset begin
        source = faulted(Int, "Error")
        actor  = KeepActor{Int}()

        @test_throws ErrorException subscribe!(source, actor)
        @test actor.values == []
        @test getvalues(actor) == []
    end

    @testset begin
        @test keep(Int) isa KeepActor{Int}
    end
end

end
