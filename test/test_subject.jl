module RocketSubjectTest

using Test
using Suppressor
using Rocket

@testset "Subject" begin

    struct DummySubjectType end

    struct NotImplementedSubject{T} end
    Rocket.as_subject(::Type{<:NotImplementedSubject{T}}) where T = ValidSubject{T}()

    struct ActorMissingSubject{T} end
    Rocket.as_subject(::Type{<:ActorMissingSubject{T}})      where T = ValidSubject{T}()
    Rocket.as_subscribable(::Type{<:ActorMissingSubject{T}}) where T = ValidSubscribable{T}()

    struct SubscribableMissingSubject{T} end
    Rocket.as_subject(::Type{<:SubscribableMissingSubject{T}})      where T = ValidSubject{T}()
    Rocket.as_actor(::Type{<:SubscribableMissingSubject{T}})        where T = BaseActorTrait{T}()

    struct ImplementedSubject{T}
        values :: Vector{T}

        ImplementedSubject{T}() where T = new(Vector{T}())
    end

    Rocket.as_subject(::Type{<:ImplementedSubject{T}})      where T = ValidSubject{T}()
    Rocket.as_actor(::Type{<:ImplementedSubject{T}})        where T = BaseActorTrait{T}()
    Rocket.as_subscribable(::Type{<:ImplementedSubject{T}}) where T = ValidSubscribable{T}()

    Rocket.on_next!(subject::ImplementedSubject{T}, data::T) where T = push!(subject.values, data)
    Rocket.on_error!(subject::ImplementedSubject, err)               = error(err)
    Rocket.on_complete!(subject::ImplementedSubject)                 = begin end

    function Rocket.on_subscribe!(subject::ImplementedSubject, actor)
        complete!(actor)
        return VoidTeardown()
    end

    @testset "as_subject" begin
        # Check if arbitrary dummy type has invalid subject type
        @test as_subject(DummySubjectType) === InvalidSubject()

        # Check if as_subject returns valid subject type for an implemented subject object
        @test as_subject(ImplementedSubject{Int}) === ValidSubject{Int}()
    end

    @testset "subscribe! as a subscribable" begin
        actor   = void(Int)
        actor_s = void(String)

        # Check if subscribe! throws an error for not valid subject being as a source
        @test_throws InvalidSubscribableTraitUsageError    subscribe!(DummySubjectType(), actor)
        @test_throws InvalidSubscribableTraitUsageError    subscribe!(SubscribableMissingSubject{Int}(), actor)
        @test_throws MissingOnSubscribeImplementationError subscribe!(ActorMissingSubject{Int}(), actor)

        # Check if subscribe! subscribes to a valid subscribable
        @test subscribe!(ImplementedSubject{Int}(), actor) === VoidTeardown()

        # Check if subscribe! throws an error if subscribable and actor data types does not match
        @test_throws InconsistentActorWithSubscribableDataTypesError subscribe!(ImplementedSubject{Int}(), actor_s)
    end

    @testset "subscribe! as an actor" begin
        source = from(1:5)

        # Check if subscribe! throws an error for not valid subject being as an actor
        @test_throws InvalidActorTraitUsageError           subscribe!(source, DummySubjectType())
        @test_throws InvalidActorTraitUsageError           subscribe!(source, ActorMissingSubject{Int}())
        @test_throws MissingOnNextImplementationError      subscribe!(source, SubscribableMissingSubject{Int}())

        # Check if subscribe! subscribes to a valid subscribable
        subject = ImplementedSubject{Int}()
        @test subscribe!(source, subject) === VoidTeardown()
        @test subject.values == [ 1, 2, 3, 4, 5 ]

        # Check if subscribe! throws an error if subscribable and actor data types does not match
        @test_throws InconsistentActorWithSubscribableDataTypesError subscribe!(source, ImplementedSubject{String}())
    end

end

end
