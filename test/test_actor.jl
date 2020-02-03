module RocketActorTest

using Test
using Rocket

@testset "Actor" begin

    struct DummyType end
    struct AbstractDummyActor <: AbstractActor{Any} end

    struct SpecifiedAbstractActor <: AbstractActor{Any} end
    Rocket.as_actor(::Type{<:SpecifiedAbstractActor}) = BaseActorTrait{Any}()

    struct NotImplementedActor           <: Actor{Any} end
    struct NotImplementedNextActor       <: NextActor{Any} end
    struct NotImplementedErrorActor      <: ErrorActor{Any} end
    struct NotImplementedCompletionActor <: CompletionActor{Any} end

    struct ImplementedActor <: Actor{Any} end
    Rocket.on_next!(::ImplementedActor, data)   = data
    Rocket.on_error!(::ImplementedActor, error) = error
    Rocket.on_complete!(::ImplementedActor)     = "ImplementedActor:complete"

    struct ImplementedNextActor <: NextActor{Any} end
    Rocket.on_next!(::ImplementedNextActor, data) = data

    struct ImplementedErrorActor <: ErrorActor{Any} end
    Rocket.on_error!(::ImplementedErrorActor, error) = error

    struct ImplementedCompletionActor <: CompletionActor{Any} end
    Rocket.on_complete!(::ImplementedCompletionActor) = "ImplementedCompletionActor:complete"

    struct IntegerActor <: Actor{Int} end
    Rocket.on_next!(::IntegerActor,  data::Int) = data
    Rocket.on_error!(::IntegerActor, err)       = err
    Rocket.on_complete!(::IntegerActor)         = "IntegerActor:complete"

    struct IntegerNextActor <: NextActor{Int} end
    Rocket.on_next!(::IntegerNextActor, data::Int) = data

    struct IntegerErrorActor <: ErrorActor{Int} end
    Rocket.on_error!(::IntegerErrorActor, err) = err

    struct IntegerCompletionActor <: CompletionActor{Int} end
    Rocket.on_complete!(::IntegerCompletionActor) = "IntegerCompletionActor:complete"

    @testset "as_actor" begin
            # Check if arbitrary dummy type has undefined actor type
            @test as_actor(DummyType) === InvalidActorTrait()

            # Check if abstract actor type has undefined actor type
            @test as_actor(AbstractActor{Any}) === InvalidActorTrait()
            @test as_actor(AbstractDummyActor) === InvalidActorTrait()

            # Check if as_teardown return specified actor type
            @test as_actor(SpecifiedAbstractActor) === BaseActorTrait{Any}()
            @test as_actor(Actor{Int})             === BaseActorTrait{Int}()
            @test as_actor(NextActor{Int})         === NextActorTrait{Int}()
            @test as_actor(ErrorActor{Int})        === ErrorActorTrait{Int}()
            @test as_actor(CompletionActor{Int})   === CompletionActorTrait{Int}()

            @test as_actor(NotImplementedActor)           === BaseActorTrait{Any}()
            @test as_actor(NotImplementedNextActor)       === NextActorTrait{Any}()
            @test as_actor(NotImplementedErrorActor)      === ErrorActorTrait{Any}()
            @test as_actor(NotImplementedCompletionActor) === CompletionActorTrait{Any}()

            @test as_actor(ImplementedActor)           === BaseActorTrait{Any}()
            @test as_actor(ImplementedNextActor)       === NextActorTrait{Any}()
            @test as_actor(ImplementedErrorActor)      === ErrorActorTrait{Any}()
            @test as_actor(ImplementedCompletionActor) === CompletionActorTrait{Any}()

            @test as_actor(IntegerActor)           === BaseActorTrait{Int}()
            @test as_actor(IntegerNextActor)       === NextActorTrait{Int}()
            @test as_actor(IntegerErrorActor)      === ErrorActorTrait{Int}()
            @test as_actor(IntegerCompletionActor) === CompletionActorTrait{Int}()
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

            # Check if next! function doing nothing for incomplete actors
            @test next!(NotImplementedErrorActor(), 1)      === nothing
            @test next!(ImplementedErrorActor(), 1)         === nothing
            @test next!(NotImplementedCompletionActor(), 1) === nothing
            @test next!(ImplementedCompletionActor(), 1)    === nothing

            # Check next! returns nothing function for implemented actors
            @test next!(ImplementedActor(),     1) === nothing
            @test next!(ImplementedActor(),     2) === nothing
            @test next!(ImplementedNextActor(), 1) === nothing
            @test next!(ImplementedNextActor(), 2) === nothing

            # Check next! function throws an error for wrong type of message
            @test_throws InconsistentSourceActorDataTypesError{Int64,String}  next!(IntegerActor(), "string")
            @test_throws InconsistentSourceActorDataTypesError{Int64,Float64} next!(IntegerActor(), 1.0)
            @test_throws InconsistentSourceActorDataTypesError{Int64,String}  next!(IntegerNextActor(), "string")
            @test_throws InconsistentSourceActorDataTypesError{Int64,Float64} next!(IntegerNextActor(), 1.0)
            @test_throws InconsistentSourceActorDataTypesError{Int64,String}  next!(IntegerErrorActor(), "string")
            @test_throws InconsistentSourceActorDataTypesError{Int64,Float64} next!(IntegerErrorActor(), 1.0)
            @test_throws InconsistentSourceActorDataTypesError{Int64,String}  next!(IntegerCompletionActor(), "string")
            @test_throws InconsistentSourceActorDataTypesError{Int64,Float64} next!(IntegerCompletionActor(), 1.0)
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
            @test error!(NotImplementedNextActor(), 1)       === nothing
            @test error!(ImplementedNextActor(), 1)          === nothing
            @test error!(NotImplementedCompletionActor(), 1) === nothing
            @test error!(ImplementedCompletionActor(), 1)    === nothing

            # Check error! function returns nothing for implemented actors
            @test error!(ImplementedActor(),      1) === nothing
            @test error!(ImplementedActor(),      2) === nothing
            @test error!(ImplementedErrorActor(), 1) === nothing
            @test error!(ImplementedErrorActor(), 2) === nothing
    end

    @testset "complete!" begin
            # Check if error! function throws an error for not valid actors
            @test_throws InvalidActorTraitUsageError complete!(DummyType())
            @test_throws InvalidActorTraitUsageError complete!(AbstractDummyActor())

            # Check if complete! function throws an error with extra argument
            @test_throws ExtraArgumentInCompleteCall complete!(ImplementedActor(), 1)

            # Check if complete! function throws an error for not implemented actors
            @test_throws MissingOnCompleteImplementationError complete!(NotImplementedActor())
            @test_throws MissingOnCompleteImplementationError complete!(NotImplementedCompletionActor())

            # Check if complete! function doing nothing for incomplete actors
            @test complete!(NotImplementedNextActor())  === nothing
            @test complete!(ImplementedNextActor())     === nothing
            @test complete!(NotImplementedErrorActor()) === nothing
            @test complete!(ImplementedErrorActor())    === nothing

            # Check complete! function returns nothing for implemented actors
            @test complete!(ImplementedActor())           === nothing
            @test complete!(ImplementedCompletionActor()) === nothing
    end

    struct CustomActor{L} <: Actor{L} end

    Rocket.on_next!(actor::CustomActor{L}, data::L) where L = begin end
    Rocket.on_error!(actor::CustomActor, err)               = begin end
    Rocket.on_complete!(actor::CustomActor)                 = begin end

    struct NotImplementedCustomActorFactory <: AbstractActorFactory end
    struct ImplementedCustomActorFactory    <: AbstractActorFactory end

    Rocket.create_actor(::Type{L}, factory::ImplementedCustomActorFactory) where L = CustomActor{L}()

    @testset "Actor Factory" begin
            @test_throws MissingCreateActorFactoryImplementationError create_actor(Int, NotImplementedCustomActorFactory())

            @test create_actor(Int, ImplementedCustomActorFactory())    === CustomActor{Int}()
            @test create_actor(String, ImplementedCustomActorFactory()) === CustomActor{String}()
    end

end

end
