module RocketVoidActorTest

using Test
using Suppressor
using Rocket

@testset "VoidActor" begin

    @testset begin
        actor = VoidActor{Int}()

        @test isempty(@capture_out next!(actor, 0))
        @test isempty(@capture_out error!(actor, "some error"))
        @test isempty(@capture_out complete!(actor))

        @test_throws InconsistentSourceActorDataTypesError{Int64,String} next!(actor, "string")
    end

    @testset begin
        @test void(Int) isa VoidActor{Int}
        @test void()    isa Rocket.VoidActorFactory
    end
end

end
