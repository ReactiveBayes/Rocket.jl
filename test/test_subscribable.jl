module RxSubscribableTest

using Test
using Suppressor
using Rx

@testset "Subscribable" begin

    struct DummyType end

    struct NotImplementedSubscribable <: Subscribable{Int} end

    struct ExplicitlyDefinedSubscribable end
    Rx.as_subscribable(::Type{<:ExplicitlyDefinedSubscribable}) = ValidSubscribable{String}()

    struct ImplementedSubscribable <: Subscribable{Int} end
    function Rx.on_subscribe!(::ImplementedSubscribable, actor)
        return Rx.VoidTeardown()
    end

    @testset "as_subscribable" begin
        # Check if arbitrary dummy type has invalid subscribable type
        @test as_subscribable(DummyType) === InvalidSubscribable()

        # Check if as_subscribable returns valid subscribable type for subtypes of Subscribable abstract type
        @test as_subscribable(NotImplementedSubscribable) === ValidSubscribable{Int}()

        # Check if as_subscribable returns valid subscribable type for explicitly defined types
        @test as_subscribable(ExplicitlyDefinedSubscribable) === ValidSubscribable{String}()
    end

    @testset "subscribe!" begin
        actor   = void(Int)
        actor_s = void(String)

        # Check if subscribe! throws an error for not valid subscribable
        @test_throws InvalidSubscribableTraitUsageError subscribe!(DummyType(), actor)
        @test_throws MissingOnSubscribeImplementationError subscribe!(NotImplementedSubscribable(), actor)
        @test_throws MissingOnSubscribeImplementationError subscribe!(ExplicitlyDefinedSubscribable(), actor_s)

        # Check if subscribe! subscribes to a valid subscribable
        @test subscribe!(ImplementedSubscribable(), actor) === Rx.VoidTeardown()

        # Check if subscribe! throws an error if subscribable and actor data types does not match
        @test_throws InconsistentActorWithSubscribableDataTypesError subscribe!(ImplementedSubscribable(), actor_s)
    end

end

end
