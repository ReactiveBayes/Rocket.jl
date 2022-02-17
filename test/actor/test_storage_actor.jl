module RocketStorageActorTest

using Test
using Rocket

@testset "StorageActor" begin

    println("Testing: actor StorageActor")

    @testset begin
        source = from([ 1, 2, 3 ])
        actor  = StorageActor{Int}()

        @test actor.value === nothing

        subscribe!(source, actor)

        @test actor.value == 3
        @test getvalues(actor) == 3
    end

    @testset begin
        source = faulted(Int, "Error")
        actor  = StorageActor{Int}()

        @test actor.value === nothing
        @test_throws ErrorException subscribe!(source, actor)
        @test actor.value === nothing
        @test getvalues(actor) === nothing
    end

    @testset begin
        @test storage(Int) isa StorageActor{Int}
        @test storage(Real) isa StorageActor{Real}
    end
end

end
