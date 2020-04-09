module RocketSyncActorTest

using Test
using Rocket

@testset "SyncActor" begin

    @testset begin
        actor  = KeepActor{Int}()
        synced = SyncActor{Int, KeepActor{Int}, -1}(actor)

        source = interval(1) |> take(5)

        subscribe!(source, synced)

        wait(synced)

        @test actor.values == [ 0, 1, 2, 3, 4 ]
    end

    @testset begin
        @test sync(void(Int)) isa SyncActor{Int, VoidActor{Int}, -1}
    end

    @testset begin
        values = Int[]

        factory  = lambda(on_next = (d) -> push!(values, d))
        synced   = sync(factory)

        subscribe!(interval(1) |> take(5), synced)

        wait(synced)

        @test values == [ 0, 1, 2, 3, 4 ]
    end

    @testset begin
        completions = []

        factory  = lambda(on_complete = () -> push!(completions, 1))
        synced   = sync(factory)

        subscribe!(completed(), synced)

        wait(synced)

        @test completions == [ 1 ]
    end

    @testset begin
        errors = []

        factory  = lambda(on_error = (d) -> push!(errors, d))
        synced   = sync(factory)

        subscribe!(throwError("e"), synced)

        wait(synced)

        @test errors == [ "e" ]
    end

    # @testset begin
    #     values = Int[]
    #
    #     factory  = lambda(on_next = (d) -> push!(values, d))
    #     synced   = sync(factory)
    #
    #     subscribe!(interval(1) |> take(5), synced)
    #     subscribe!(interval(1) |> take(5), synced)
    #
    #     wait(synced)
    #
    #     subscribe!(interval(1) |> take(5), synced)
    #
    #     wait(synced)
    #
    #     @test values == [0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 0, 1, 2, 3, 4]
    # end

    @testset begin
        source = never(Int)
        actor  = sync(void(Int), timeout = 100)

        subscribe!(source, actor)

        @test_throws SyncActorTimedOutException wait(actor)
    end

    struct DummyActor end

    @testset begin
        @test_throws InvalidActorTraitUsageError sync(DummyActor())
    end
end

end
