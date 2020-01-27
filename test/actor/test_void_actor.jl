module RxVoidActorTest

using Test
using Suppressor
using Rx

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
        @test void()    isa Rx.VoidActorFactory
    end
end

end
