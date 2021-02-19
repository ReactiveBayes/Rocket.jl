module RocketBufferActorTest

using Test
using Rocket

@testset "BufferActor" begin

    println("Testing: actor BufferActor")

    @testset begin
        source = of([ 1, 2, 3 ])
        actor  = BufferActor{Int}(3)

        subscribe!(source, actor)

        @test actor.values == [ 1, 2, 3 ]
        @test getvalues(actor) == [ 1, 2, 3 ]
    end

    @testset begin
        source = from([ [ 1, 2, 3 ], [ 4, 5, 6 ] ])
        actor  = BufferActor{Int}(3)

        subscribe!(source, actor)

        @test actor.values == [ 4, 5, 6 ]
        @test getvalues(actor) == [ 4, 5, 6 ]
    end

    @testset begin
        source = faulted(Vector{Int}, "Error")
        actor  = BufferActor{Int}(3)

        @test_throws ErrorException subscribe!(source, actor)
    end

    @testset begin
        @test buffer(Int, 3) isa BufferActor{Int}
    end
end

end
