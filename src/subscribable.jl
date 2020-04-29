export SubscribableTrait, ValidSubscribableTrait, SimpleSubscribableTrait, ScheduledSubscribableTrait, InvalidSubscribable
export AbstractSubscribable, Subscribable, ScheduledSubscribable, as_subscribable
export subscribe!, on_subscribe!
export subscribable_extract_type

export InvalidSubscribableTraitUsageError, InconsistentActorWithSubscribableDataTypesError
export MissingOnSubscribeImplementationError, MissingOnScheduledSubscribeImplementationError

import Base: show
import Base: eltype

"""
Abstract type for all possible subscribable traits

See also: [`ValidSubscribableTrait`](@ref), [`InvalidSubscribable`](@ref)
"""
abstract type SubscribableTrait end

"""
Abstract type for all possible valid subscribable traits.
There are two subtypes for `ValidSubscribableTrait`: `SimpleSubscribableTrait` and `ScheduledSubscribableTrait`

See also: [`SubscribableTrait`](@ref), [`SimpleSubscribableTrait`](@ref), [`ScheduledSubscribableTrait`](@ref)
"""
abstract type ValidSubscribableTrait{T} <: SubscribableTrait end

"""
Simple subscribable trait behavior. Simple subscribable can be used in subscribe! function and just executes `on_subscribe!` method for provided subscribable.
`SimpleSubscribableTrait` is a subtype of `ValidSubscribableTrait`.

See also: [`SubscribableTrait`](@ref), [`ValidSubscribableTrait`](@ref), [`Subscribable`](@ref), [`subscribe!`](@ref), [`on_subscribe!`](@ref)
"""
struct SimpleSubscribableTrait{T} <: ValidSubscribableTrait{T} end

"""
Scheduled subscribable trait behavior. Scheduled subscribable can be used in subscribe! function and executes `on_subscribe!` method for provided subscribable with custom scheduling.
`ScheduledSubscribableTrait` is a subtype of `ValidSubscribableTrait`.

See also: [`SubscribableTrait`](@ref), [`ValidSubscribableTrait`](@ref), [`ScheduledSubscribable`](@ref), [`subscribe!`](@ref), [`on_subscribe!`](@ref)
"""
struct ScheduledSubscribableTrait{T} <: ValidSubscribableTrait{T} end

"""
Default subscribable trait behavior for all types. Invalid subscribable cannot be used in subscribe! function, doing so will throw an error.

See also: [`SubscribableTrait`](@ref), [`subscribe!`](@ref)
"""
struct InvalidSubscribable  <: SubscribableTrait end

"""
Supertype type for `Subscribable` and `ScheduledSubscribable` types.

See also: [`Actor`](@ref), [`NextActor`](@ref), [`ErrorActor`](@ref), [`CompletionActor`](@ref)
"""
abstract type AbstractSubscribable{T} end

"""
Super type for any simple subscribable object. Automatically specifies a `SimpleSubscribableTrait` trait behavior.
Objects with specified `SimpleSubscribableTrait` subscribable trait must implement: `on_subscribe!(subscribable, actor)` method.
`Subscribable` is a subtype of `AbstractSubscribable` type.

# Examples
```jldoctest
using Rocket

struct MySubscribable <: Subscribable{String} end

Rocket.as_subscribable(MySubscribable)

# output

SimpleSubscribableTrait{String}()

```

See also: [`SubscribableTrait`](@ref), [`ValidSubscribableTrait`](@ref), [`SimpleSubscribableTrait`](@ref)
"""
abstract type Subscribable{T} <: AbstractSubscribable{T} end

"""
Super type for any scheduled subscribable object. Automatically specifies a `ScheduledSubscribableTrait` trait behavior.
Objects with specified `ScheduledSubscribableTrait` subscribable trait must implement: `on_subscribe!(subscribable, actor, scheduler)` method.
`ScheduledSubscribable` is a subtype of `AbstractSubscribable` type.

# Examples
```jldoctest
using Rocket

struct MyScheduledSubscribable <: ScheduledSubscribable{String} end

Rocket.as_subscribable(MyScheduledSubscribable)

# output

ScheduledSubscribableTrait{String}()

```

See also: [`SubscribableTrait`](@ref), [`ValidSubscribableTrait`](@ref), [`ScheduledSubscribableTrait`](@ref)
"""
abstract type ScheduledSubscribable{T} <: AbstractSubscribable{T} end

"""
    as_subscribable(::Type)

This function checks subscribable trait behavior specification. Can be used explicitly to specify subscribable trait behavior for any object.

See also: [`subscribe!`](@ref)
"""
as_subscribable(::Type)                                     = InvalidSubscribable()
as_subscribable(::Type{<:Subscribable{T}})          where T = SimpleSubscribableTrait{T}()
as_subscribable(::Type{<:ScheduledSubscribable{T}}) where T = ScheduledSubscribableTrait{T}()

subscribable_extract_type(type::Type{S}) where S = subscribable_extract_type(as_subscribable(S), type)
subscribable_extract_type(source::S)     where S = subscribable_extract_type(as_subscribable(S), source)

subscribable_extract_type(::ValidSubscribableTrait{T}, source) where T = T
subscribable_extract_type(::InvalidSubscribable,       source)         = throw(InvalidSubscribableTraitUsageError(source))

subscribable_extract_type(::ValidSubscribableTrait{T}, type::Type{S}) where { T, S } = T
subscribable_extract_type(::InvalidSubscribable,       type::Type{S}) where {    S } = throw(InvalidSubscribableTraitUsageError(S))

Base.eltype(source::Type{S}) where { T, S <: AbstractSubscribable{T} } = T
Base.eltype(source::S)       where { T, S <: AbstractSubscribable{T} } = T

"""
    subscribe!(subscribable::T, actor::S) where T where S

`subscribe!` function is used to attach an actor to subscribable.
It also checks types of subscribable and actors to be a valid Subscribable and Actor objects respectively.
Passing not valid subscribable or/and actor object will throw an error.

# Arguments
- `subscribable`: valid subscribable object
- `actor`: valid actor object

# Examples

```jldoctest
using Rocket

source = from((1, 2, 3))
subscribe!(source, logger())
;

# output

[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Data: 3
[LogActor] Completed
```

```jldoctest
using Rocket

source = from((1, 2, 3))
subscribe!(source, 1)
;

# output

ERROR: Type Int64 is not a valid actor type.
[...]
```

```jldoctest
using Rocket

source = from((1, 2, 3))
subscribe!(1, logger())
;

# output

ERROR: Type Int64 is not a valid subscribable type.
[...]
```

See also: [`on_subscribe!`](@ref), [`as_subscribable`](@ref)
"""
function subscribe!(subscribable::T, actor::S) where { T, S }
    return subscribable_on_subscribe!(as_subscribable(T), as_actor(S), subscribable, actor)
end

function subscribe!(subscribable::T, factory::F) where { T, F <: AbstractActorFactory }
    return subscribable_on_subscribe_with_factory!(as_subscribable(T), subscribable, factory)
end

subscribable_on_subscribe!(::InvalidSubscribable,   S,                     subscribable, actor)                  = throw(InvalidSubscribableTraitUsageError(subscribable))
subscribable_on_subscribe!(::ValidSubscribableTrait{T},  ::InvalidActorTrait,   subscribable, actor) where T          = throw(InvalidActorTraitUsageError(actor))
subscribable_on_subscribe!(::ValidSubscribableTrait{T1}, ::ValidActorTrait{T2}, subscribable, actor) where { T1, T2 } = throw(InconsistentActorWithSubscribableDataTypesError{T1, T2}(subscribable, actor))

function subscribable_on_subscribe!(::SimpleSubscribableTrait{T1}, ::ValidActorTrait{T2}, subscribable, actor) where { T2, T1 <: T2 }
    return on_subscribe!(subscribable, actor)
end

function subscribable_on_subscribe!(::ScheduledSubscribableTrait{T1}, ::ValidActorTrait{T2}, subscribable, actor) where { T2, T1 <: T2 }
    return scheduled_subscription!(subscribable, actor, getscheduler(subscribable))
end

subscribable_on_subscribe_with_factory!(::InvalidSubscribable, subscribable, factory) = throw(InvalidSubscribableTraitUsageError(subscribable))

function subscribable_on_subscribe_with_factory!(::ValidSubscribableTrait{L}, subscribable, factory) where L
    return subscribe!(subscribable, create_actor(L, factory))
end

"""
    on_subscribe!(subscribable, actor)
    on_subscribe!(subscribable, actor, scheduler)

Every valid subscribable object have to define its own method for `on_subscribe!` function which specifies subscription logic
and has return a valid `Teardown` object.

Objects with specified `SimpleSubscribableTrait` subscribable trait must implement: `on_subscribe!(subscribable, actor)` method.
Objects with specified `ScheduledSubscribableTrait` subscribable trait must implement: `on_subscribe!(subscribable, actor, scheduler)` method.

# Arguments
- `subscribable`: Subscribable object
- `actor`: Actor object
- `scheduler`: Scheduler object (only for scheduled subscribables)

# Examples

```jldoctest
using Rocket

struct MySubscribable <: Subscribable{Int} end

function Rocket.on_subscribe!(subscribable::MySubscribable, actor)
    next!(actor, 0)
    complete!(actor)
    return VoidTeardown()
end

subscribe!(MySubscribable(), logger())
;

# output

[LogActor] Data: 0
[LogActor] Completed
```

```jldoctest
using Rocket

struct MyScheduledSubscribable <: ScheduledSubscribable{Int} end

Rocket.getscheduler(::MyScheduledSubscribable) = Rocket.AsapScheduler()

function Rocket.on_subscribe!(subscribable::MyScheduledSubscribable, actor, scheduler)
    next!(actor, 0, scheduler)
    complete!(actor, scheduler)
    return VoidTeardown()
end

subscribe!(MyScheduledSubscribable(), logger())
;

# output

[LogActor] Data: 0
[LogActor] Completed
```

See also: [`Subscribable`](@ref), [`ScheduledSubscribable`](@ref), [`SimpleSubscribableTrait`](@ref), [`ScheduledSubscribableTrait`](@ref), [`Teardown`](@ref), [`logger`](@ref)
"""
on_subscribe!(subscribable, actor)            = throw(MissingOnSubscribeImplementationError(subscribable))
on_subscribe!(subscribable, actor, scheduler) = throw(MissingOnScheduledSubscribeImplementationError(subscribable))

# -------------------------------- #
# Errors                           #
# -------------------------------- #

"""
This error will be thrown if `subscribe!` function is called with invalid subscribable object

See also: [`subscribe!`](@ref)
"""
struct InvalidSubscribableTraitUsageError
    subscribable
end

function Base.show(io::IO, err::InvalidSubscribableTraitUsageError)
    print(io, "Type $(typeof(err.subscribable)) is not a valid subscribable type. \nConsider extending your subscribable with Subscribable{T} abstract type or implement as_subscribable(::Type{<:$(typeof(err.subscribable))}).")
end

"""
This error will be thrown if `subscribe!` function is called with inconsistent subscribable and actor objects

See also: [`subscribe!`](@ref)
"""
struct InconsistentActorWithSubscribableDataTypesError{T1, T2}
    subscribable
    actor
end

function Base.show(io::IO, err::InconsistentActorWithSubscribableDataTypesError{T1, T2}) where T1 where T2
    print(io, "Actor of type $(typeof(err.actor)) expects data to be of type $(T2), while subscribable of type $(typeof(err.subscribable)) produces data of type $(T1).")
end

"""
This error will be thrown if Julia cannot find specific method of 'on_subscribe!()' function for given subscribable and actor

See also: [`on_subscribe!`](@ref)
"""
struct MissingOnSubscribeImplementationError
    subscribable
end

function Base.show(io::IO, err::MissingOnSubscribeImplementationError)
    print(io, "You probably forgot to implement on_subscribe!(subscribable::$(typeof(err.subscribable)), actor).")
end

"""
This error will be thrown if Julia cannot find specific method of 'on_subscribe!()' function for given subscribable, actor and scheduler

See also: [`on_subscribe!`](@ref)
"""
struct MissingOnScheduledSubscribeImplementationError
    subscribable
end

function Base.show(io::IO, err::MissingOnScheduledSubscribeImplementationError)
    print(io, "You probably forgot to implement on_subscribe!(subscribable::$(typeof(err.subscribable)), actor, scheduler).")
end
