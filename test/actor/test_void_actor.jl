module RocketVoidActorTest

using Test
using Rocket

@testset "VoidActor" begin

    @testset begin
        actor = VoidActor{Int}()

        @test_throws InconsistentSourceActorDataTypesError{Int64,String} next!(actor, "string")
    end

    @testset begin
        factory = void()

        @test Rocket.create_actor(Int, factory) isa VoidActor{Int}
    end

    @testset begin
        @test void(Int) isa VoidActor{Int}
        @test void()    isa Rocket.VoidActorFactory
    end
end

end
