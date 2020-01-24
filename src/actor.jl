export InvalidActorTrait, BaseActorTrait, NextActorTrait, ErrorActorTrait, CompletionActorTrait, ActorTrait
export AbstractActor, Actor, NextActor, ErrorActor, CompletionActor
export AbstractActorFactory, create_actor
export next!, error!, complete!
export on_next!, on_error!, on_complete!
export as_actor
export is_exhausted

export InvalidActorTraitUsageError, InconsistentSourceActorDataTypesError
export MissingDataArgumentInNextCall, MissingErrorArgumentInErrorCall, ExtraArgumentInCompleteCall
export MissingOnNextImplementationError, MissingOnErrorImplementationError, MissingOnCompleteImplementationError
export MissingIsExhaustedImplementationError
export MissingCreateActorFactoryImplementationError

import Base: show

"""
Abstract type for all possible actor traits

See also: [`Actor`](@ref), [`BaseActorTrait`](@ref), [`NextActorTrait`](@ref), [`ErrorActorTrait`](@ref), [`CompletionActorTrait`](@ref), [`InvalidActorTrait`](@ref)
"""
abstract type ActorTrait{T} end

"""
Base actor trait specifies actor to listen for all `next!`, `error!` and `complete!` events.

See also: [`ActorTrait`](@ref), [`Actor`](@ref)
"""
struct BaseActorTrait{T}       <: ActorTrait{T}       end

"""
Next actor trait specifies actor to listen for `next!` events only.

See also: [`ActorTrait`](@ref), [`NextActor`](@ref)
"""
struct NextActorTrait{T}       <: ActorTrait{T}       end

"""
Error actor trait specifies actor to listen for `error!` events only.

See also: [`ActorTrait`](@ref), [`ErrorActor`](@ref)
"""
struct ErrorActorTrait{T}      <: ActorTrait{T}       end

"""
Completion actor trait specifies actor to listen for `complete!` events only.

See also: [`ActorTrait`](@ref), [`CompletionActor`](@ref)
"""
struct CompletionActorTrait{T} <: ActorTrait{T}       end

"""
Default actor trait behavior for any object. Actor with such a trait specificaion cannot be used as a valid actor in `subscribe!` function.
Doing so will raise an error.
"""
struct InvalidActorTrait       <: ActorTrait{Nothing} end

"""
Abstract type for any actor object

See also: [`Actor`](@ref), [`NextActor`](@ref), [`ErrorActor`](@ref), [`CompletionActor`](@ref)
"""
abstract type AbstractActor{T} end

"""
Can be used as a super type for common actor. Automatically specifies a `BaseActorTrait` trait behavior.
Each `Actor` must implement its own methods for 'on_next!(actor, data)', 'on_error!(actor, err)' and 'on_complete!(actor)' functions.

See also: [`AbstractActor`](@ref), [`BaseActorTrait`](@ref), [`ActorTrait`](@ref), [`on_next!`](@ref), [`on_error!`](@ref), [`on_complete!`](@ref)
"""
abstract type Actor{T}           <: AbstractActor{T} end

"""
Can be used as a super type for "next-only" actor. Automatically specifies a `NextActorTrait` trait behavior.
Each `NextActor` must implement its own methods for 'on_next!(actor, data)' function only.

See also: [`AbstractActor`](@ref), [`NextActorTrait`](@ref), [`ActorTrait`](@ref), [`on_next!`](@ref)
"""
abstract type NextActor{T}       <: AbstractActor{T} end

"""
Can be used as a super type for "error-only" actor. Automatically specifies a `ErrorActorTrait` trait behavior.
Each `ErrorActor` must implement its own methods for 'on_error!(actor, err)' function only.

See also: [`AbstractActor`](@ref), [`ErrorActorTrait`](@ref), [`ActorTrait`](@ref), [`on_error!`](@ref)
"""
abstract type ErrorActor{T}      <: AbstractActor{T} end

"""
Can be used as a super type for "completion-only" actor. Automatically specifies a `CompletionActorTrait` trait behavior.
Each `CompletionActor` must implement its own methods for 'on_complete!(actor)' function only.

See also: [`AbstractActor`](@ref), [`CompletionActorTrait`](@ref), [`ActorTrait`](@ref), [`on_complete!`](@ref)
"""
abstract type CompletionActor{T} <: AbstractActor{T} end

"""
    as_actor(::Type)

This function checks actor trait behavior specification. May be used explicitly to specify actor trait behavior for any object.

See also: [`ActorTrait`](@ref)
"""
as_actor(::Type)                  = InvalidActorTrait()
as_actor(::Type{<:AbstractActor}) = InvalidActorTrait()

as_actor(::Type{<:Actor{T}})           where T = BaseActorTrait{T}()
as_actor(::Type{<:NextActor{T}})       where T = NextActorTrait{T}()
as_actor(::Type{<:ErrorActor{T}})      where T = ErrorActorTrait{T}()
as_actor(::Type{<:CompletionActor{T}}) where T = CompletionActorTrait{T}()

next!(actor)            = throw(MissingDataArgumentInNextCall())
error!(actor)           = throw(MissingErrorArgumentInErrorCall())
complete!(actor, extra) = throw(ExtraArgumentInCompleteCall())

"""
    next!(actor, data)

This function is used to deliver a "next" event to an actor with some `data`

See also: [`AbstractActor`](@ref), [`on_next!`](@ref)
"""
next!(actor::T,  data)  where T = actor_on_next!(as_actor(T), actor, data)

"""
    error!(actor, err)

This function is used to deliver a "error" event to an actor with some `err`

See also: [`AbstractActor`](@ref), [`on_error!`](@ref)
"""
error!(actor::T, err)   where T = actor_on_error!(as_actor(T), actor, err)

"""
    complete!(actor)

This function is used to deliver a "complete" event to an actor

See also: [`AbstractActor`](@ref), [`on_complete!`](@ref)
"""
complete!(actor::T)     where T = actor_on_complete!(as_actor(T), actor)

"""
    is_exhausted(actor)

This function is used to check if actor can handle any further message events

See also: [`AbstractActor`](@ref)
"""
is_exhausted(actor) = false # throw(MissingIsExhaustedImplementationError(actor))

actor_on_next!(::InvalidActorTrait,       actor, data)                     = throw(InvalidActorTraitUsageError(actor))
actor_on_next!(::BaseActorTrait{T},       actor, data::R) where R where T  = throw(InconsistentSourceActorDataTypesError{T, R}(actor))
actor_on_next!(::NextActorTrait{T},       actor, data::R) where R where T  = throw(InconsistentSourceActorDataTypesError{T, R}(actor))
actor_on_next!(::ErrorActorTrait{T},      actor, data::R) where R where T  = throw(InconsistentSourceActorDataTypesError{T, R}(actor))
actor_on_next!(::CompletionActorTrait{T}, actor, data::R) where R where T  = throw(InconsistentSourceActorDataTypesError{T, R}(actor))
actor_on_next!(::BaseActorTrait{T},       actor, data::R) where { R <: T } where T = begin on_next!(actor, data); return nothing end
actor_on_next!(::NextActorTrait{T},       actor, data::R) where { R <: T } where T = begin on_next!(actor, data); return nothing end
actor_on_next!(::ErrorActorTrait{T},      actor, data::R) where { R <: T } where T = begin end
actor_on_next!(::CompletionActorTrait{T}, actor, data::R) where { R <: T } where T = begin end

actor_on_error!(::InvalidActorTrait,    actor, err) = throw(InvalidActorTraitUsageError(actor))
actor_on_error!(::BaseActorTrait,       actor, err) = begin on_error!(actor, err); return nothing end
actor_on_error!(::NextActorTrait,       actor, err) = begin end
actor_on_error!(::ErrorActorTrait,      actor, err) = begin on_error!(actor, err); return nothing end
actor_on_error!(::CompletionActorTrait, actor, err) = begin end

actor_on_complete!(::InvalidActorTrait,    actor) = throw(InvalidActorTraitUsageError(actor))
actor_on_complete!(::BaseActorTrait,       actor) = begin on_complete!(actor); return nothing end
actor_on_complete!(::NextActorTrait,       actor) = begin end
actor_on_complete!(::ErrorActorTrait,      actor) = begin end
actor_on_complete!(::CompletionActorTrait, actor) = begin on_complete!(actor); return nothing end

"""
    on_next!(actor, data)

Both Actor and NextActor objects must implement its own method for `on_next!` function which will be called on "next" event.

See also: [`Actor`](@ref), [`NextActor`](@ref)
"""
on_next!(actor, data)   = throw(MissingOnNextImplementationError(actor, data))

"""
    on_error!(actor, err)

Both Actor and ErrorActor objects must implement its own method for `on_error!` function which will be called on "error" event.

See also: [`Actor`](@ref), [`ErrorActor`](@ref)
"""
on_error!(actor, err)   = throw(MissingOnErrorImplementationError(actor))

"""
    on_complete!(actor)

Both Actor and CompletionActor objects must implement its own method for `on_complete!` function which will be called on "complete" event.

See also: [`Actor`](@ref), [`ErrorActor`](@ref)
"""
on_complete!(actor)     = throw(MissingOnCompleteImplementationError(actor))



# -------------------------------- #
# Actor factory                    #
# -------------------------------- #



"""
Abstract type for all possible actor factories

See also: [`Actor`](@ref)
"""
abstract type AbstractActorFactory end

"""
    create_actor(::Type{L}, factory::F) where L where { F <: AbstractActorFactory }

Actor creator function for a given factory `F`. Should be implemented explicitly for any `AbstractActorFactory` object

See also: [`AbstractActorFactory`](@ref), [`MissingCreateActorFactoryImplementationError`](@ref)
"""
create_actor(::Type{L}, factory::F) where L where { F <: AbstractActorFactory } = throw(MissingCreateActorFactoryImplementationError(factory))

"""
This error will be throw if Julia cannot find specific method of 'create_actor()' function for given actor factory

See also: [`AbstractActorFactory`](@ref), [`create_actor`](@ref)
"""
struct MissingCreateActorFactoryImplementationError
    factory
end

function Base.show(io::IO, err::MissingCreateActorFactoryImplementationError)
    print(io, "You probably forgot to implement create_actor(::Type{L}, factory::$(typeof(err.factory))).")
end



# -------------------------------- #
# Errors                           #
# -------------------------------- #

"""
This error will be thrown if `next!`, `error!` or `complete!` functions are called with invalid actor object

See also: [`next!`](@ref), [`error!`](@ref), [`complete!`](@ref), [`InvalidActorTrait`](@ref)
"""
struct InvalidActorTraitUsageError
    actor
end

function Base.show(io::IO, err::InvalidActorTraitUsageError)
    print(io, "Type $(typeof(err.actor)) is not a valid actor type. \nConsider extending your actor with one of the abstract actor types <: (Actor{T}, NextActor{T}, ErrorActor{T}, CompletionActor{T}) or implement as_actor(::Type{<:$(typeof(err.actor))}).")
end


"""
This error will be thrown if `next!` function is called with inconsistent data type

See also: [`AbstractActor`](@ref), [`Subscribable`](@ref), [`next!`](@ref)
"""
struct InconsistentSourceActorDataTypesError{T, R}
    actor
end

function Base.show(io::IO, err::InconsistentSourceActorDataTypesError{T, R}) where T where R
    print(io, "Actor of type $(typeof(err.actor)) expects data to be of type $(T), but $(R) was found.")
end

"""
This error will be thrown if `next!` function is called without data argument

See also: [`next!`](@ref)
"""
struct MissingDataArgumentInNextCall end

function Base.show(io::IO, ::MissingDataArgumentInNextCall)
    print(io, "Missing data argument in next! callback")
end

"""
This error will be thrown if `error!` function is called without err argument

See also: [`error!`](@ref)
"""
struct MissingErrorArgumentInErrorCall end

function Base.show(io::IO, ::MissingErrorArgumentInErrorCall)
    print(io, "Missing err argument in error! callback")
end

"""
This error will be thrown if `complete!` function is called with extra data/err argument

See also: [`complete!`](@ref)
"""
struct ExtraArgumentInCompleteCall end

function Base.show(io::IO, ::ExtraArgumentInCompleteCall)
    print(io, "Extra argument in complete! callback")
end

"""
This error will be thrown if Julia cannot find specific method of 'on_next!()' function for given actor and data

See also: [`on_next!`](@ref)
"""
struct MissingOnNextImplementationError
    actor
    data
end

function Base.show(io::IO, err::MissingOnNextImplementationError)
    print(io, "You probably forgot to implement on_next!(actor::$(typeof(err.actor)), data::$(typeof(err.data))).")
end

"""
This error will be thrown if Julia cannot find specific method of 'on_error!()' function for given actor

See also: [`on_error!`](@ref)
"""
struct MissingOnErrorImplementationError
    actor
end

function Base.show(io::IO, err::MissingOnErrorImplementationError)
    print(io, "You probably forgot to implement on_error!(actor::$(typeof(err.actor)), err).")
end

"""
This error will be thrown if Julia cannot find specific method of 'on_complete!()' function for given actor and data

See also: [`on_next!`](@ref)
"""
struct MissingOnCompleteImplementationError
    actor
end

function Base.show(io::IO, err::MissingOnCompleteImplementationError)
    print(io, "You probably forgot to implement on_complete!(actor::$(typeof(err.actor))).")
end

"""
This error will be throw if Julia cannot find specific method of 'is_exhausted()' function for given actor

See also: [`is_exhausted`](@ref)
"""
struct MissingIsExhaustedImplementationError
    actor
end

function Base.show(io::IO, err::MissingIsExhaustedImplementationError)
    print(io, "You probably forgot to implement is_exhausted(actor::$(typeof(err.actor))).")
end
