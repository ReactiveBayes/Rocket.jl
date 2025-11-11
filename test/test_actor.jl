module RocketActorTest

using Test
using Rocket

@testset "Actor" begin

    struct DummyType end
    struct AbstractDummyActor <: AbstractActor{Any} end

    struct SpecifiedAbstractActor end
    Rocket.as_actor(::Type{<: SpecifiedAbstractActor}) = BaseActorTrait{Int}()

    struct NotImplementedActor <: Actor{Any}
        events::Vector{Any}

        NotImplementedActor() = new(Vector{Any}())
    end

    struct NotImplementedNextActor <: NextActor{Int}
        events::Vector{Any}

        NotImplementedNextActor() = new(Vector{Any}())
    end

    struct NotImplementedErrorActor <: ErrorActor{Float64}
        events::Vector{Any}

        NotImplementedErrorActor() = new(Vector{Any}())
    end

    struct NotImplementedCompletionActor <: CompletionActor{String}
        events::Vector{Any}

        NotImplementedCompletionActor() = new(Vector{Any}())
    end

    struct ImplementedActor <: Actor{Any}
        events::Vector{Any}

        ImplementedActor() = new(Vector{Any}())
    end

    Rocket.on_next!(actor::ImplementedActor, data) = push!(actor.events, data)
    Rocket.on_error!(actor::ImplementedActor, err) = push!(actor.events, "err: $err")
    Rocket.on_complete!(actor::ImplementedActor) = push!(actor.events, "completed")

    struct ImplementedNextActor <: NextActor{Int}
        events::Vector{Any}

        ImplementedNextActor() = new(Vector{Any}())
    end

    Rocket.on_next!(actor::ImplementedNextActor, data) = push!(actor.events, data)
    Rocket.on_error!(actor::ImplementedNextActor, err) = push!(actor.events, "err: $err")
    Rocket.on_complete!(actor::ImplementedNextActor) = push!(actor.events, "completed")

    struct ImplementedErrorActor <: ErrorActor{Float64}
        events::Vector{Any}

        ImplementedErrorActor() = new(Vector{Any}())
    end

    Rocket.on_next!(actor::ImplementedErrorActor, data) = push!(actor.events, data)
    Rocket.on_error!(actor::ImplementedErrorActor, err) = push!(actor.events, "err: $err")
    Rocket.on_complete!(actor::ImplementedErrorActor) = push!(actor.events, "completed")

    struct ImplementedCompletionActor <: CompletionActor{String}
        events::Vector{Any}

        ImplementedCompletionActor() = new(Vector{Any}())
    end

    Rocket.on_next!(actor::ImplementedCompletionActor, data) = push!(actor.events, data)
    Rocket.on_error!(actor::ImplementedCompletionActor, err) =
        push!(actor.events, "err: $err")
    Rocket.on_complete!(actor::ImplementedCompletionActor) =
        push!(actor.events, "completed")

    @testset "as_actor" begin
        # Check if arbitrary dummy type has undefined actor type
        @test as_actor(DummyType) === InvalidActorTrait()

        # Check if abstract actor type has undefined actor type
        @test as_actor(AbstractActor{Any}) === InvalidActorTrait()
        @test as_actor(AbstractDummyActor) === InvalidActorTrait()

        # Check if as_teardown return specified actor type
        @test as_actor(SpecifiedAbstractActor) === BaseActorTrait{Int}()
        @test as_actor(Actor{Any}) === BaseActorTrait{Any}()
        @test as_actor(NextActor{Int}) === NextActorTrait{Int}()
        @test as_actor(ErrorActor{Float64}) === ErrorActorTrait{Float64}()
        @test as_actor(CompletionActor{String}) === CompletionActorTrait{String}()

        @test as_actor(NotImplementedActor) === BaseActorTrait{Any}()
        @test as_actor(NotImplementedNextActor) === NextActorTrait{Int}()
        @test as_actor(NotImplementedErrorActor) === ErrorActorTrait{Float64}()
        @test as_actor(NotImplementedCompletionActor) === CompletionActorTrait{String}()

        @test as_actor(ImplementedActor) === BaseActorTrait{Any}()
        @test as_actor(ImplementedNextActor) === NextActorTrait{Int}()
        @test as_actor(ImplementedErrorActor) === ErrorActorTrait{Float64}()
        @test as_actor(ImplementedCompletionActor) === CompletionActorTrait{String}()
    end

    @testset "next!" begin
        # Check if next! function throws an error for not valid actors
        @test_throws InvalidActorTraitUsageError next!(DummyType(), 1)
        @test_throws InvalidActorTraitUsageError next!(AbstractDummyActor(), 1)

        # Check if next! function throws an error without data argument
        @test_throws MissingDataArgumentInNextCall next!(ImplementedActor())

        # Check if next! function throws an error for not implemented actors
        @test_throws MissingOnNextImplementationError next!(NotImplementedActor(), 1)
        @test_throws MissingOnNextImplementationError next!(NotImplementedNextActor(), 1)

        # Check if next! function does nothing for incomplete actors
        actor = NotImplementedErrorActor()
        @test next!(actor, 1.0) === nothing
        @test actor.events == []

        actor = ImplementedErrorActor()
        @test next!(actor, 1.0) === nothing
        @test actor.events == []

        actor = NotImplementedCompletionActor()
        @test next!(actor, "1.0") === nothing
        @test actor.events == []

        actor = ImplementedCompletionActor()
        @test next!(actor, "1.0") === nothing
        @test actor.events == []

        # Check next! function returns nothing and saves incoming event in events array for implemented actors
        actor = ImplementedActor()
        @test next!(actor, 1) === nothing
        @test actor.events == [1]
        @test next!(actor, 2) === nothing
        @test actor.events == [1, 2]

        actor = ImplementedNextActor()
        @test next!(actor, 1) === nothing
        @test actor.events == [1]
        @test next!(actor, 2) === nothing
        @test actor.events == [1, 2]

        # Check next! function accepts wider types of data
        actor = ImplementedActor()
        @test next!(actor, 1) === nothing
        @test next!(actor, 1.0) === nothing
        @test next!(actor, "1") === nothing
        @test actor.events == [1, 1.0, "1"]

        # Check next! function throws an error for wrong type of message
        @test_throws InconsistentSourceActorDataTypesError{Int64,String} next!(
            ImplementedNextActor(),
            "string",
        )
        @test_throws InconsistentSourceActorDataTypesError{Int64,Float64} next!(
            ImplementedNextActor(),
            1.0,
        )
        @test_throws InconsistentSourceActorDataTypesError{Int64,String} next!(
            NotImplementedNextActor(),
            "string",
        )
        @test_throws InconsistentSourceActorDataTypesError{Int64,Float64} next!(
            NotImplementedNextActor(),
            1.0,
        )
        @test_throws InconsistentSourceActorDataTypesError{Float64,String} next!(
            ImplementedErrorActor(),
            "string",
        )
        @test_throws InconsistentSourceActorDataTypesError{Float64,Int} next!(
            ImplementedErrorActor(),
            1,
        )
        @test_throws InconsistentSourceActorDataTypesError{Float64,String} next!(
            NotImplementedErrorActor(),
            "string",
        )
        @test_throws InconsistentSourceActorDataTypesError{Float64,Int} next!(
            NotImplementedErrorActor(),
            1,
        )
        @test_throws InconsistentSourceActorDataTypesError{String,Float64} next!(
            ImplementedCompletionActor(),
            1.0,
        )
        @test_throws InconsistentSourceActorDataTypesError{String,Int} next!(
            ImplementedCompletionActor(),
            1,
        )
        @test_throws InconsistentSourceActorDataTypesError{String,Float64} next!(
            NotImplementedCompletionActor(),
            1.0,
        )
        @test_throws InconsistentSourceActorDataTypesError{String,Int} next!(
            NotImplementedCompletionActor(),
            1,
        )
    end

    @testset "error!" begin
        # Check if error! function throws an error for not valid actors
        @test_throws InvalidActorTraitUsageError error!(DummyType(), 1)
        @test_throws InvalidActorTraitUsageError error!(AbstractDummyActor(), 1)

        # Check if error! function throws an error without error argument
        @test_throws MissingErrorArgumentInErrorCall error!(ImplementedActor())

        # Check if error! function throws an error for not implemented actors
        @test_throws MissingOnErrorImplementationError error!(NotImplementedActor(), 1)
        @test_throws MissingOnErrorImplementationError error!(NotImplementedErrorActor(), 1)

        # Check if error! function doing nothing for incomplete actors
        actor = ImplementedNextActor()
        @test error!(actor, 1) === nothing
        @test actor.events == []

        actor = NotImplementedNextActor()
        @test error!(actor, 1) === nothing
        @test actor.events == []

        actor = ImplementedCompletionActor()
        @test error!(actor, 1) === nothing
        @test actor.events == []

        actor = NotImplementedCompletionActor()
        @test error!(actor, 1) === nothing
        @test actor.events == []

        # Check error! function returns nothing and saves incoming event in events array for implemented actors
        actor = ImplementedActor()
        @test error!(actor, 1) === nothing
        @test actor.events == ["err: 1"]
        @test error!(actor, 1.0) === nothing
        @test actor.events == ["err: 1", "err: 1.0"]
        @test error!(actor, "err") === nothing
        @test actor.events == ["err: 1", "err: 1.0", "err: err"]

        actor = ImplementedErrorActor()
        @test error!(actor, 1) === nothing
        @test actor.events == ["err: 1"]
        @test error!(actor, 1.0) === nothing
        @test actor.events == ["err: 1", "err: 1.0"]
        @test error!(actor, "err") === nothing
        @test actor.events == ["err: 1", "err: 1.0", "err: err"]
    end

    @testset "complete!" begin
        # Check if error! function throws an error for not valid actors
        @test_throws InvalidActorTraitUsageError complete!(DummyType())
        @test_throws InvalidActorTraitUsageError complete!(AbstractDummyActor())

        # Check if complete! function throws an error for not implemented actors
        @test_throws MissingOnCompleteImplementationError complete!(NotImplementedActor())
        @test_throws MissingOnCompleteImplementationError complete!(
            NotImplementedCompletionActor(),
        )

        # Check if complete! function doing nothing for incomplete actors
        actor = ImplementedNextActor()
        @test complete!(actor) === nothing
        @test actor.events == []

        actor = NotImplementedNextActor()
        @test complete!(actor) === nothing
        @test actor.events == []

        actor = ImplementedErrorActor()
        @test complete!(actor) === nothing
        @test actor.events == []

        actor = NotImplementedErrorActor()
        @test complete!(actor) === nothing
        @test actor.events == []

        # Check complete! function returns nothing and saves incoming event in events array for implemented actors
        actor = ImplementedActor()
        @test complete!(actor) === nothing
        @test actor.events == ["completed"]

        actor = ImplementedCompletionActor()
        @test complete!(actor) === nothing
        @test actor.events == ["completed"]
    end

    struct CustomActor{L} <: Actor{L} end

    Rocket.on_next!(actor::CustomActor{L}, data::L) where {L} = begin end
    Rocket.on_error!(actor::CustomActor, err) = begin end
    Rocket.on_complete!(actor::CustomActor) = begin end

    struct NotImplementedCustomActorFactory <: AbstractActorFactory end
    struct ImplementedCustomActorFactory <: AbstractActorFactory end

    Rocket.create_actor(::Type{L}, factory::ImplementedCustomActorFactory) where {L} =
        CustomActor{L}()

    @testset "Actor Factory" begin
        @test_throws MissingCreateActorFactoryImplementationError create_actor(
            Int,
            NotImplementedCustomActorFactory(),
        )

        @test create_actor(Int, ImplementedCustomActorFactory()) === CustomActor{Int}()
        @test create_actor(String, ImplementedCustomActorFactory()) ===
              CustomActor{String}()
    end

    @testset "Actor extract type and eltype" begin

        @test Rocket.actor_extract_type(SpecifiedAbstractActor) === Int
        @test Rocket.actor_extract_type(NotImplementedActor) === Any
        @test Rocket.actor_extract_type(NotImplementedNextActor) === Int
        @test Rocket.actor_extract_type(NotImplementedErrorActor) === Float64
        @test Rocket.actor_extract_type(NotImplementedCompletionActor) === String
        @test Rocket.actor_extract_type(ImplementedActor) === Any
        @test Rocket.actor_extract_type(ImplementedNextActor) === Int
        @test Rocket.actor_extract_type(ImplementedErrorActor) === Float64
        @test Rocket.actor_extract_type(ImplementedCompletionActor) === String

        @test eltype(SpecifiedAbstractActor) === Any
        @test eltype(NotImplementedActor) === Any
        @test eltype(NotImplementedNextActor) === Int
        @test eltype(NotImplementedErrorActor) === Float64
        @test eltype(NotImplementedCompletionActor) === String
        @test eltype(ImplementedActor) === Any
        @test eltype(ImplementedNextActor) === Int
        @test eltype(ImplementedErrorActor) === Float64
        @test eltype(ImplementedCompletionActor) === String

        @test Rocket.actor_extract_type(SpecifiedAbstractActor()) === Int
        @test Rocket.actor_extract_type(NotImplementedActor()) === Any
        @test Rocket.actor_extract_type(NotImplementedNextActor()) === Int
        @test Rocket.actor_extract_type(NotImplementedErrorActor()) === Float64
        @test Rocket.actor_extract_type(NotImplementedCompletionActor()) === String
        @test Rocket.actor_extract_type(ImplementedActor()) === Any
        @test Rocket.actor_extract_type(ImplementedNextActor()) === Int
        @test Rocket.actor_extract_type(ImplementedErrorActor()) === Float64
        @test Rocket.actor_extract_type(ImplementedCompletionActor()) === String

        @test eltype(SpecifiedAbstractActor()) === Any
        @test eltype(NotImplementedActor()) === Any
        @test eltype(NotImplementedNextActor()) === Int
        @test eltype(NotImplementedErrorActor()) === Float64
        @test eltype(NotImplementedCompletionActor()) === String
        @test eltype(ImplementedActor()) === Any
        @test eltype(ImplementedNextActor()) === Int
        @test eltype(ImplementedErrorActor()) === Float64
        @test eltype(ImplementedCompletionActor()) === String

        @test_throws InvalidActorTraitUsageError Rocket.actor_extract_type(DummyType)
        @test_throws InvalidActorTraitUsageError Rocket.actor_extract_type(
            AbstractDummyActor,
        )

        @test_throws InvalidActorTraitUsageError Rocket.actor_extract_type(DummyType())
        @test_throws InvalidActorTraitUsageError Rocket.actor_extract_type(
            AbstractDummyActor(),
        )
    end

end

end
