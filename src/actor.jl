export ValidActorTrait, InvalidActorTrait, BaseActorTrait, NextActorTrait, ErrorActorTrait, CompletionActorTrait, ActorTrait
export AbstractActor, Actor, NextActor, ErrorActor, CompletionActor
export AbstractActorFactory, create_actor
export next!, error!, complete!
export on_next!, on_error!, on_complete!
export as_actor, actor_extract_type

export InvalidActorTraitUsageError, InconsistentSourceActorDataTypesError
export MissingDataArgumentInNextCall, MissingErrorArgumentInErrorCall, ExtraArgumentInCompleteCall
export MissingOnNextImplementationError, MissingOnErrorImplementationError, MissingOnCompleteImplementationError
export MissingCreateActorFactoryImplementationError

import Base: show
import Base: eltype

"""
Abstract type for all possible actor traits

See also: [`Actor`](@ref), [`ValidActorTrait`](@ref), [`BaseActorTrait`](@ref), [`NextActorTrait`](@ref), [`ErrorActorTrait`](@ref), [`CompletionActorTrait`](@ref), [`InvalidActorTrait`](@ref)
"""
abstract type ActorTrait end

"""
Abstract type for all possible valid actor traits.
There are several subtypes for `ValidActorTrait`: `BaseActorTrait`, `NextActorTrait`, `ErrorActorTrait` and `CompletionActorTrait`.

See also: [`Actor`](@ref), [`BaseActorTrait`](@ref), [`NextActorTrait`](@ref), [`ErrorActorTrait`](@ref), [`CompletionActorTrait`](@ref), [`InvalidActorTrait`](@ref)
"""
abstract type ValidActorTrait{T} <: ActorTrait end

"""
Base actor trait specifies actor to listen for all `next!`, `error!` and `complete!` events.
`BaseActorTrait` is a subtype of `ValidActorTrait`.

See also: [`ActorTrait`](@ref), [`ValidActorTrait`](@ref), [`Actor`](@ref)
"""
struct BaseActorTrait{T} <: ValidActorTrait{T}       end

"""
Next actor trait specifies actor to listen for `next!` events only.
`NextActorTrait` is a subtype of `ValidActorTrait`.

See also: [`ActorTrait`](@ref), [`ValidActorTrait`](@ref), [`NextActor`](@ref)
"""
struct NextActorTrait{T} <: ValidActorTrait{T}       end

"""
Error actor trait specifies actor to listen for `error!` events only.
`ErrorActorTrait` is a subtype of `ValidActorTrait`.

See also: [`ActorTrait`](@ref), [`ValidActorTrait`](@ref), [`ErrorActor`](@ref)
"""
struct ErrorActorTrait{T} <: ValidActorTrait{T}       end

"""
Completion actor trait specifies actor to listen for `complete!` events only.
`CompletionActorTrait` is a subtype of `ValidActorTrait`.

See also: [`ActorTrait`](@ref), [`ValidActorTrait`](@ref), [`CompletionActor`](@ref)
"""
struct CompletionActorTrait{T} <: ValidActorTrait{T}       end

"""
Default actor trait behavior for any object. Actor with such a trait specificaion cannot be used as a valid actor in `subscribe!` function.
Doing so will raise an error. `InvalidActorTrait` is a subtype of `ActorTrait`.

See also: [`ActorTrait`](@ref)
"""
struct InvalidActorTrait <: ActorTrait end

"""
Supertype type for `Actor`, `NextActor`, `ErrorActor` and `CompletionActor` types.

See also: [`Actor`](@ref), [`NextActor`](@ref), [`ErrorActor`](@ref), [`CompletionActor`](@ref)
"""
abstract type AbstractActor{T} end

"""
Can be used as a super type for common actor. Automatically specifies a `BaseActorTrait` trait behavior.
Every `Actor` must implement its own methods for `on_next!(actor, data)`, `on_error!(actor, err)` and `on_complete!(actor)` functions.
`Actor` is a subtype of `AbstractActor` type.

# Examples
```jldoctest
using Rocket

struct MyActor <: Actor{String} end

Rocket.as_actor(MyActor)

# output

BaseActorTrait{String}()
```

See also: [`AbstractActor`](@ref), [`BaseActorTrait`](@ref), [`ActorTrait`](@ref), [`on_next!`](@ref), [`on_error!`](@ref), [`on_complete!`](@ref)
"""
abstract type Actor{T} <: AbstractActor{T} end

"""
Can be used as a super type for "next-only" actor. Automatically specifies a `NextActorTrait` trait behavior.
Every `NextActor` must implement its own methods for `on_next!(actor, data)` function only.
`NextActor` is a subtype of `AbstractActor` type.

# Examples
```jldoctest
using Rocket

struct MyNextActor <: NextActor{String} end

Rocket.as_actor(MyNextActor)

# output

NextActorTrait{String}()
```

See also: [`AbstractActor`](@ref), [`NextActorTrait`](@ref), [`ActorTrait`](@ref), [`on_next!`](@ref)
"""
abstract type NextActor{T} <: AbstractActor{T} end

"""
Can be used as a super type for "error-only" actor. Automatically specifies a `ErrorActorTrait` trait behavior.
Every `ErrorActor` must implement its own methods for `on_error!(actor, err)` function only.
`ErrorActor` is a subtype of `AbstractActor` type.

# Examples
```jldoctest
using Rocket

struct MyErrorActor <: ErrorActor{String} end

Rocket.as_actor(MyErrorActor)

# output

ErrorActorTrait{String}()
```

See also: [`AbstractActor`](@ref), [`ErrorActorTrait`](@ref), [`ActorTrait`](@ref), [`on_error!`](@ref)
"""
abstract type ErrorActor{T} <: AbstractActor{T} end

"""
Can be used as a super type for "completion-only" actor. Automatically specifies a `CompletionActorTrait` trait behavior.
Every `CompletionActor` must implement its own methods for `on_complete!(actor)` function only.
`CompletionActor` is a subtype of `AbstractActor` type.

# Examples
```jldoctest
using Rocket

struct MyCompletionActor <: CompletionActor{String} end

Rocket.as_actor(MyCompletionActor)

# output

CompletionActorTrait{String}()
```

See also: [`AbstractActor`](@ref), [`CompletionActorTrait`](@ref), [`ActorTrait`](@ref), [`on_complete!`](@ref)
"""
abstract type CompletionActor{T} <: AbstractActor{T} end

"""
    as_actor(::Type)

This function checks actor trait behavior specification. May be used explicitly to specify actor trait behavior for any object.

See also: [`ActorTrait`](@ref), [`ValidActorTrait`](@ref), [`InalidActorTrait`](@ref)
"""
as_actor(::Type)                               = InvalidActorTrait()
as_actor(::Type{<:AbstractActor})              = InvalidActorTrait()
as_actor(::Type{<:Actor{T}})           where T = BaseActorTrait{T}()
as_actor(::Type{<:NextActor{T}})       where T = NextActorTrait{T}()
as_actor(::Type{<:ErrorActor{T}})      where T = ErrorActorTrait{T}()
as_actor(::Type{<:CompletionActor{T}}) where T = CompletionActorTrait{T}()

actor_extract_type(type::Type{A}) where A = actor_extract_type(as_actor(A), type)
actor_extract_type(actor::A)      where A = actor_extract_type(as_actor(A), actor)

actor_extract_type(::ValidActorTrait{T}, actor) where T = T
actor_extract_type(::InvalidActorTrait,  actor)         = throw(InvalidActorTraitUsageError(actor))

actor_extract_type(::ValidActorTrait{T}, type::Type{A}) where { T, A } = T
actor_extract_type(::InvalidActorTrait,  type::Type{A}) where {    A } = throw(InvalidActorTraitUsageError(type))

Base.eltype(actor::Type{A}) where { T, A <: AbstractActor{T} } = T
Base.eltype(actor::A)       where { T, A <: AbstractActor{T} } = T

next!(actor)  = throw(MissingDataArgumentInNextCall())
error!(actor) = throw(MissingErrorArgumentInErrorCall())

"""
    next!(actor, data)
    next!(actor, data, scheduler)

This function is used to deliver a "next" event to an actor with some `data`. Takes optional `scheduler` object to schedule execution of data delivery.

See also: [`AbstractActor`](@ref), [`on_next!`](@ref)
"""
next!(actor::T, data)            where T = actor_on_next!(as_actor(T), actor, data)
next!(actor::T, data, scheduler) where T = actor_on_next!(as_actor(T), actor, data, scheduler)

"""
    error!(actor, err)
    error!(actor, err, scheduler)

This function is used to deliver a "error" event to an actor with some `err`. Takes optional `scheduler` object to schedule execution of error delivery.

See also: [`AbstractActor`](@ref), [`on_error!`](@ref)
"""
error!(actor::T, err)            where T = actor_on_error!(as_actor(T), actor, err)
error!(actor::T, err, scheduler) where T = actor_on_error!(as_actor(T), actor, err, scheduler)

"""
    complete!(actor)
    complete!(actor, scheduler)

This function is used to deliver a "complete" event to an actor. Takes optional `scheduler` object to schedule execution of complete event delivery.

See also: [`AbstractActor`](@ref), [`on_complete!`](@ref)
"""
complete!(actor::T)            where T = actor_on_complete!(as_actor(T), actor)
complete!(actor::T, scheduler) where T = actor_on_complete!(as_actor(T), actor, scheduler)

actor_on_next!(::InvalidActorTrait,       actor, data)                     = throw(InvalidActorTraitUsageError(actor))
actor_on_next!(::ValidActorTrait{T},      actor, data::R) where R where T  = throw(InconsistentSourceActorDataTypesError{T, R}(actor))

actor_on_next!(::BaseActorTrait{T},       actor, data::R) where { R <: T } where T = begin on_next!(actor, data); return nothing end
actor_on_next!(::NextActorTrait{T},       actor, data::R) where { R <: T } where T = begin on_next!(actor, data); return nothing end
actor_on_next!(::ErrorActorTrait{T},      actor, data::R) where { R <: T } where T = begin end
actor_on_next!(::CompletionActorTrait{T}, actor, data::R) where { R <: T } where T = begin end

actor_on_next!(::BaseActorTrait{T},       actor, data::R, scheduler) where { R <: T } where T = begin scheduled_next!(actor, data, scheduler); return nothing end
actor_on_next!(::NextActorTrait{T},       actor, data::R, scheduler) where { R <: T } where T = begin scheduled_next!(actor, data, scheduler); return nothing end
actor_on_next!(::ErrorActorTrait{T},      actor, data::R, scheduler) where { R <: T } where T = begin end
actor_on_next!(::CompletionActorTrait{T}, actor, data::R, scheduler) where { R <: T } where T = begin end

actor_on_error!(::InvalidActorTrait,    actor, err) = throw(InvalidActorTraitUsageError(actor))

actor_on_error!(::BaseActorTrait,       actor, err) = begin on_error!(actor, err); return nothing end
actor_on_error!(::NextActorTrait,       actor, err) = begin end
actor_on_error!(::ErrorActorTrait,      actor, err) = begin on_error!(actor, err); return nothing end
actor_on_error!(::CompletionActorTrait, actor, err) = begin end

actor_on_error!(::BaseActorTrait,       actor, err, scheduler) = begin scheduled_error!(actor, err, scheduler); return nothing end
actor_on_error!(::NextActorTrait,       actor, err, scheduler) = begin end
actor_on_error!(::ErrorActorTrait,      actor, err, scheduler) = begin scheduled_error!(actor, err, scheduler); return nothing end
actor_on_error!(::CompletionActorTrait, actor, err, scheduler) = begin end

actor_on_complete!(::InvalidActorTrait,    actor) = throw(InvalidActorTraitUsageError(actor))

actor_on_complete!(::BaseActorTrait,       actor) = begin on_complete!(actor); return nothing end
actor_on_complete!(::NextActorTrait,       actor) = begin end
actor_on_complete!(::ErrorActorTrait,      actor) = begin end
actor_on_complete!(::CompletionActorTrait, actor) = begin on_complete!(actor); return nothing end

actor_on_complete!(::BaseActorTrait,       actor, scheduler) = begin scheduled_complete!(actor, scheduler); return nothing end
actor_on_complete!(::NextActorTrait,       actor, scheduler) = begin end
actor_on_complete!(::ErrorActorTrait,      actor, scheduler) = begin end
actor_on_complete!(::CompletionActorTrait, actor, scheduler) = begin scheduled_complete!(actor, scheduler); return nothing end

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
