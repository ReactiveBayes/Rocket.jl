module RocketSubscribableTest

using Test
using Rocket

@testset "Subscribable" begin

    struct DummyType end

    struct NotImplementedSubscribable <: Subscribable{Int} end
    struct NotImplementedScheduledSubscribable <: ScheduledSubscribable{Int} end
    Rocket.getscheduler(::NotImplementedScheduledSubscribable) = AsapScheduler()

    struct ExplicitlyDefinedSimpleSubscribable end
    Rocket.as_subscribable(::Type{<:ExplicitlyDefinedSimpleSubscribable}) = SimpleSubscribableTrait{String}()

    struct ExplicitlyDefinedScheduledSubscribable end
    Rocket.as_subscribable(::Type{<:ExplicitlyDefinedScheduledSubscribable}) = ScheduledSubscribableTrait{String}()
    Rocket.getscheduler(::ExplicitlyDefinedScheduledSubscribable) = AsapScheduler()

    struct ImplementedSimpleSubscribable <: Subscribable{Int} end

    function Rocket.on_subscribe!(::ImplementedSimpleSubscribable, actor)
        next!(actor, 1)
        return voidTeardown
    end

    struct ImplementedScheduledSubscribable <: ScheduledSubscribable{Int} end
    Rocket.getscheduler(::ImplementedScheduledSubscribable) = AsapScheduler()

    function Rocket.on_subscribe!(::ImplementedScheduledSubscribable, actor, scheduler)
        next!(actor, 1, scheduler)
        return voidTeardown
    end

    @testset "as_subscribable" begin
        # Check if arbitrary dummy type has invalid subscribable type
        @test as_subscribable(DummyType) === InvalidSubscribableTrait()

        # Check if as_subscribable returns valid subscribable type for subtypes of Subscribable abstract type
        @test as_subscribable(NotImplementedSubscribable)          === SimpleSubscribableTrait{Int}()
        @test as_subscribable(NotImplementedScheduledSubscribable) === ScheduledSubscribableTrait{Int}()

        # Check if as_subscribable returns valid subscribable type for explicitly defined types
        @test as_subscribable(ExplicitlyDefinedSimpleSubscribable)    === SimpleSubscribableTrait{String}()
        @test as_subscribable(ExplicitlyDefinedScheduledSubscribable) === ScheduledSubscribableTrait{String}()
    end

    struct SimpleActor{T} <: Actor{T}
        events :: Vector{Any}

        SimpleActor{T}() where T = new(Vector{Any}())
    end

    Rocket.on_next!(actor::SimpleActor, data) = push!(actor.events, data)
    Rocket.on_error!(actor::SimpleActor, err) = push!(actor.events, "err: $err")
    Rocket.on_next!(actor::SimpleActor)       = push!(actor.events, "completed")

    @testset "subscribe!" begin
        # Check if subscribe! throws an error for not valid subscribable
        @test_throws InvalidSubscribableTraitUsageError             subscribe!(DummyType(), void(Any))
        @test_throws InvalidActorTraitUsageError                    subscribe!(NotImplementedSubscribable(), DummyType())
        @test_throws MissingOnSubscribeImplementationError          subscribe!(NotImplementedSubscribable(), void(Any))
        @test_throws MissingOnScheduledSubscribeImplementationError subscribe!(NotImplementedScheduledSubscribable(), void(Any))
        @test_throws MissingOnSubscribeImplementationError          subscribe!(ExplicitlyDefinedSimpleSubscribable(), void(Any))
        @test_throws MissingOnScheduledSubscribeImplementationError subscribe!(ExplicitlyDefinedScheduledSubscribable(), void(Any))

        # Check if subscribe! subscribes to a valid subscribable
        actor = SimpleActor{Int}()
        @test subscribe!(ImplementedSimpleSubscribable(), actor) === voidTeardown
        @test actor.events == [ 1 ]

        actor = SimpleActor{Int}()
        @test subscribe!(ImplementedScheduledSubscribable(), actor) === voidTeardown
        @test actor.events == [ 1 ]

        # Check if subscribe! throws an error if subscribable and actor data types does not match
        actor = SimpleActor{String}()
        @test_throws InconsistentActorWithSubscribableDataTypesError subscribe!(ImplementedSimpleSubscribable(), actor)
        @test actor.events == [ ]

        actor = SimpleActor{String}()
        @test_throws InconsistentActorWithSubscribableDataTypesError subscribe!(ImplementedScheduledSubscribable(), actor)
        @test actor.events == [ ]
    end

    struct NotImplementedFactory <: AbstractActorFactory end

    struct ImplementedFactory <: AbstractActorFactory end

    actor = SimpleActor{Int}()

    Rocket.create_actor(::Type{Int}, factory::ImplementedFactory) = actor

    @testset "subscribe! with factory" begin
        @test_throws MissingCreateActorFactoryImplementationError subscribe!(ImplementedSimpleSubscribable(), NotImplementedFactory())
        @test_throws MissingCreateActorFactoryImplementationError subscribe!(ImplementedScheduledSubscribable(), NotImplementedFactory())

        @test subscribe!(ImplementedSimpleSubscribable(), ImplementedFactory()) === voidTeardown
        @test actor.events == [ 1 ]

        @test subscribe!(ImplementedScheduledSubscribable(), ImplementedFactory()) === voidTeardown
        @test actor.events == [ 1, 1 ]
    end


    @testset "Subscribable extract type and eltype" begin

        @test Rocket.subscribable_extract_type(NotImplementedSubscribable)             === Int
        @test Rocket.subscribable_extract_type(NotImplementedScheduledSubscribable)    === Int
        @test Rocket.subscribable_extract_type(ExplicitlyDefinedSimpleSubscribable)    === String
        @test Rocket.subscribable_extract_type(ExplicitlyDefinedScheduledSubscribable) === String
        @test Rocket.subscribable_extract_type(ImplementedSimpleSubscribable)          === Int
        @test Rocket.subscribable_extract_type(ImplementedScheduledSubscribable)       === Int

        @test eltype(NotImplementedSubscribable)             === Int
        @test eltype(NotImplementedScheduledSubscribable)    === Int
        @test eltype(ExplicitlyDefinedSimpleSubscribable)    === Any
        @test eltype(ExplicitlyDefinedScheduledSubscribable) === Any
        @test eltype(ImplementedSimpleSubscribable)          === Int
        @test eltype(ImplementedScheduledSubscribable)       === Int

        @test Rocket.subscribable_extract_type(NotImplementedSubscribable())             === Int
        @test Rocket.subscribable_extract_type(NotImplementedScheduledSubscribable())    === Int
        @test Rocket.subscribable_extract_type(ExplicitlyDefinedSimpleSubscribable())    === String
        @test Rocket.subscribable_extract_type(ExplicitlyDefinedScheduledSubscribable()) === String
        @test Rocket.subscribable_extract_type(ImplementedSimpleSubscribable())          === Int
        @test Rocket.subscribable_extract_type(ImplementedScheduledSubscribable())       === Int

        @test eltype(NotImplementedSubscribable())             === Int
        @test eltype(NotImplementedScheduledSubscribable())    === Int
        @test eltype(ExplicitlyDefinedSimpleSubscribable())    === Any
        @test eltype(ExplicitlyDefinedScheduledSubscribable()) === Any
        @test eltype(ImplementedSimpleSubscribable())          === Int
        @test eltype(ImplementedScheduledSubscribable())       === Int

        @test_throws InvalidSubscribableTraitUsageError Rocket.subscribable_extract_type(DummyType)
        @test_throws InvalidSubscribableTraitUsageError Rocket.subscribable_extract_type(DummyType())

        @test eltype(DummyType) === Any
        @test eltype(DummyType()) === Any

    end
end

end
