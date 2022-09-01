module RocketKeepActorTest

using Test
using Rocket
using DataStructures

@testset "CircularKeepActor" begin

    println("Testing: actor CircularKeepActor")

    @testset begin
        source = from([ 1, 2, 3 ])
        actor  = CircularKeepActor{Int}(2)

        subscribe!(source, actor)

        @test actor.values == [ 2, 3 ]
        @test getvalues(actor) == [ 2, 3 ]
    end

    @testset begin
        source = from(1:100)
        actor  = CircularKeepActor{Int}(2)

        subscribe!(source, actor)

        @test actor.values == [ 99, 100 ]
        @test getvalues(actor) == [ 99, 100 ]
        @test length(getvalues(actor)) == 2
    end

    @testset begin
        source = from([ 1, 2, 3 ])
        actor  = CircularKeepActor{Int}(2)

        subscribe!(source, actor)

        @test actor[1] === 2
        @test actor[2] === 3

        @test collect(actor) == [ 2, 3 ]
    end

    @testset begin
        source = from([ 1, 2, 3 ])
        actor  = CircularKeepActor{Int}(2)

        subscribe!(source, actor)

        i = 2
        for item in actor
            @test item === i
            i += 1
        end
    end

    @testset begin
        source = from([ 1, 2, 3 ])
        actor  = CircularKeepActor{Int}(2)

        subscribe!(source, actor)

        @test actor[1:end] == [ 2, 3 ]
    end

    @testset begin
        source = faulted(Int, "Error")
        actor  = CircularKeepActor{Int}(2)

        @test_throws ErrorException subscribe!(source, actor)
        @test actor.values == []
        @test getvalues(actor) == []
    end

    @testset begin
        @test circularkeep(Int, 3) isa CircularKeepActor{Int}
        @test capacity(getvalues(circularkeep(Int, 3))) === 3
    end
end

end
