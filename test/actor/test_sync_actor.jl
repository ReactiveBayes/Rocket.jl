module RocketSyncActorTest

using Test
using Rocket

@testset "SyncActor" begin

    println("Testing: actor SyncActor")

    @testset begin
        actor = KeepActor{Int}()
        synced = sync(actor; withlock = true)

        source = interval(1) |> take(5)

        subscribe!(source, synced)

        wait(synced)

        @test actor.values == [0, 1, 2, 3, 4]
    end

    @testset begin
        @test sync(void(Int)) isa SyncActor{Int,VoidActor{Int}}
    end

    @testset begin
        values = Int[]

        factory = lambda(on_next = (d) -> push!(values, d))
        synced = sync(factory; withlock = true)

        subscribe!(interval(1) |> take(5), synced)

        wait(synced)

        @test values == [0, 1, 2, 3, 4]
    end

    @testset begin
        completions = []

        factory = lambda(on_complete = () -> push!(completions, 1))
        synced = sync(factory; withlock = true)

        subscribe!(completed(), synced)

        wait(synced)

        @test completions == [1]
    end

    @testset begin
        errors = []

        factory = lambda(on_error = (d) -> push!(errors, d))
        synced = sync(factory; withlock = true)

        subscribe!(faulted("e"), synced)

        wait(synced)

        @test errors == ["e"]
    end

    @testset begin
        actor = KeepActor{Int}()
        synced = sync(actor; withlock = false)

        source = interval(1) |> take(5)

        subscribe!(source, synced)

        wait(synced)

        @test actor.values == [0, 1, 2, 3, 4]
    end

    @testset begin
        values = Int[]

        factory = lambda(on_next = (d) -> push!(values, d))
        synced = sync(factory; withlock = false)

        subscribe!(interval(1) |> take(5), synced)

        wait(synced)

        @test values == [0, 1, 2, 3, 4]
    end

    @testset begin
        completions = []

        factory = lambda(on_complete = () -> push!(completions, 1))
        synced = sync(factory; withlock = false)

        subscribe!(completed(), synced)

        wait(synced)

        @test completions == [1]
    end

    @testset begin
        errors = []

        factory = lambda(on_error = (d) -> push!(errors, d))
        synced = sync(factory; withlock = false)

        subscribe!(faulted("e"), synced)

        wait(synced)

        @test errors == ["e"]
    end

    @testset begin
        source = never(Int)
        actor = sync(void(Int); withlock = false, timeout = 100)

        subscribe!(source, actor)

        @test_throws SyncActorTimedOutException wait(actor)
    end

    struct DummyActor end

    @testset begin
        @test_throws InvalidActorTraitUsageError sync(DummyActor())
    end
end

end
