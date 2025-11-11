module RocketSubjectTest

using Test
using Rocket

@testset "Subject" begin

    struct DummySubjectType end

    struct NotImplementedSubject{T} end
    Rocket.as_subject(::Type{<:NotImplementedSubject{T}}) where {T} = ValidSubjectTrait{T}()

    struct ActorMissingSubject{T} end
    Rocket.as_subject(::Type{<:ActorMissingSubject{T}}) where {T} = ValidSubjectTrait{T}()
    Rocket.as_subscribable(::Type{<:ActorMissingSubject{T}}) where {T} =
        SimpleSubscribableTrait{T}()

    struct SubscribableMissingSubject{T} end
    Rocket.as_subject(::Type{<:SubscribableMissingSubject{T}}) where {T} =
        ValidSubjectTrait{T}()
    Rocket.as_actor(::Type{<:SubscribableMissingSubject{T}}) where {T} = BaseActorTrait{T}()

    struct ImplementedSubject{T}
        values::Vector{T}

        ImplementedSubject{T}() where {T} = new(Vector{T}())
    end

    Rocket.as_subject(::Type{<:ImplementedSubject{T}}) where {T} = ValidSubjectTrait{T}()
    Rocket.as_actor(::Type{<:ImplementedSubject{T}}) where {T} = BaseActorTrait{T}()
    Rocket.as_subscribable(::Type{<:ImplementedSubject{T}}) where {T} =
        SimpleSubscribableTrait{T}()

    Rocket.on_next!(subject::ImplementedSubject{T}, data::T) where {T} =
        push!(subject.values, data)
    Rocket.on_error!(subject::ImplementedSubject, err) = error(err)
    Rocket.on_complete!(subject::ImplementedSubject) = begin end

    function Rocket.on_subscribe!(subject::ImplementedSubject, actor)
        complete!(actor)
        return voidTeardown
    end

    struct ImplementedAutoSubject{T} <: AbstractSubject{T}
        values::Vector{T}

        ImplementedAutoSubject{T}() where {T} = new(Vector{T}())
    end

    Rocket.on_next!(subject::ImplementedAutoSubject{T}, data::T) where {T} =
        push!(subject.values, data)
    Rocket.on_error!(subject::ImplementedAutoSubject, err) = error(err)
    Rocket.on_complete!(subject::ImplementedAutoSubject) = begin end

    function Rocket.on_subscribe!(subject::ImplementedAutoSubject, actor)
        complete!(actor)
        return voidTeardown
    end

    @testset "as_subject" begin
        # Check if arbitrary dummy type has invalid subject type
        @test as_subject(DummySubjectType) === InvalidSubjectTrait()

        # Check if as_subject returns valid subject type for an implemented subject object
        @test as_subject(ImplementedSubject{Int}) === ValidSubjectTrait{Int}()
        @test as_subject(ImplementedAutoSubject{Int}) === ValidSubjectTrait{Int}()

        @test as_actor(ImplementedSubject{Int}) === BaseActorTrait{Int}()
        @test as_actor(ImplementedAutoSubject{Int}) === BaseActorTrait{Int}()

        @test as_subscribable(ImplementedSubject{Int}) === SimpleSubscribableTrait{Int}()
        @test as_subscribable(ImplementedAutoSubject{Int}) ===
              SimpleSubscribableTrait{Int}()
    end

    @testset "subscribe! as a subscribable" begin
        actor = void(Int)
        actor_s = void(String)

        # Check if subscribe! throws an error for not valid subject being as a source
        @test_throws InvalidSubscribableTraitUsageError subscribe!(
            DummySubjectType(),
            actor,
        )
        @test_throws InvalidSubscribableTraitUsageError subscribe!(
            SubscribableMissingSubject{Int}(),
            actor,
        )
        @test_throws MissingOnSubscribeImplementationError subscribe!(
            ActorMissingSubject{Int}(),
            actor,
        )

        # Check if subscribe! subscribes to a valid subscribable
        @test subscribe!(ImplementedSubject{Int}(), actor) === voidTeardown
        @test subscribe!(ImplementedAutoSubject{Int}(), actor) === voidTeardown

        # Check if subscribe! throws an error if subscribable and actor data types does not match
        @test_throws InconsistentActorWithSubscribableDataTypesError subscribe!(
            ImplementedSubject{Int}(),
            actor_s,
        )
        @test_throws InconsistentActorWithSubscribableDataTypesError subscribe!(
            ImplementedAutoSubject{Int}(),
            actor_s,
        )
    end

    @testset "subscribe! as an actor" begin
        source = from(1:5)

        # Check if subscribe! throws an error for not valid subject being as an actor
        @test_throws InvalidActorTraitUsageError subscribe!(source, DummySubjectType())
        @test_throws InvalidActorTraitUsageError subscribe!(
            source,
            ActorMissingSubject{Int}(),
        )
        @test_throws MissingOnNextImplementationError subscribe!(
            source,
            SubscribableMissingSubject{Int}(),
        )

        # Check if subscribe! subscribes to a valid subscribable
        subject = ImplementedSubject{Int}()
        @test subscribe!(source, subject) === voidTeardown
        @test subject.values == [1, 2, 3, 4, 5]

        # Check if subscribe! subscribes to a valid subscribable
        subject = ImplementedAutoSubject{Int}()
        @test subscribe!(source, subject) === voidTeardown
        @test subject.values == [1, 2, 3, 4, 5]

        # Check if subscribe! throws an error if subscribable and actor data types does not match
        @test_throws InconsistentActorWithSubscribableDataTypesError subscribe!(
            source,
            ImplementedSubject{String}(),
        )
        @test_throws InconsistentActorWithSubscribableDataTypesError subscribe!(
            source,
            ImplementedAutoSubject{String}(),
        )
    end

    struct DummyFactory end

    struct NotImplementedSubjectFactory <: AbstractSubjectFactory end

    struct ImplementedSubjectFactory <: AbstractSubjectFactory end

    create_subject(::Type{L}, factory::ImplementedSubjectFactory) where {L} =
        ImplementedSubject{L}()

    @testset "test AbstractSubjectFactory" begin
        @test_throws MethodError create_subject(Int, DummyFactory())
        @test_throws MethodError create_subject(Int, NotImplementedSubjectFactory())

        actor = create_subject(String, ImplementedSubjectFactory())
        @test actor isa ImplementedSubject{String}
    end

end

end
