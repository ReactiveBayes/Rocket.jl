module RocketSyncActorTest

using Test
using Rocket

@testset "SyncActor" begin

    @testset begin
        actor  = KeepActor{Int}()
        synced = SyncActor{Int, KeepActor{Int}}(actor)

        source = timer(0, 1) |> take(5)

        subscribe!(source, synced)

        wait(synced)

        @test actor.values == [ 0, 1, 2, 3, 4 ]
    end

    @testset begin
        @test sync(void(Int)) isa SyncActor{Int, VoidActor{Int}}
    end
end

end
