export SubscribableTrait, ValidSubscribable, SimpleSubscribableTrait, ScheduledSubscribableTrait, InvalidSubscribable
export Subscribable, ScheduledSubscribable, as_subscribable
export subscribe!, on_subscribe!
export subscribable_extract_type

export InvalidSubscribableTraitUsageError, InconsistentActorWithSubscribableDataTypesError
export MissingOnSubscribeImplementationError

import Base: show
import Base: eltype

"""
Abstract type for all possible subscribable traits

See also: [`ValidSubscribable`](@ref), [`InvalidSubscribable`](@ref)
"""
abstract type SubscribableTrait end

"""
Abstract type for all possible valid subscribable traits

See also: [`SubscribableTrait`](@ref), [`SimpleSubscribable`](@ref)
"""
abstract type ValidSubscribable{T} <: SubscribableTrait end

"""
Simple subscribable trait behavior. Simple subscribable can be used in subscribe! function and do not use any schedulers for execution logic

See also: [`SubscribableTrait`](@ref), [`Subscribable`](@ref)
"""
struct SimpleSubscribableTrait{T} <: ValidSubscribable{T} end

"""
Scheduled subscribable trait behavior. Scheduled subscribable can be used in subscribe! function and uses schedulers for execution logic

See also: [`SubscribableTrait`](@ref), [`Subscribable`](@ref)
"""
struct ScheduledSubscribableTrait{T} <: ValidSubscribable{T} end

"""
Default subscribable trait behavior for all types. Invalid subscribable cannot be used in subscribe! function, doing so will throw an error.

See also: [`SubscribableTrait`](@ref), [`subscribe!`](@ref)
"""
struct InvalidSubscribable  <: SubscribableTrait end

"""
Super type for any simple subscribable object. Automatically specifies a `SimpleSubscribableTrait` trait behavior.

# Examples
```jldoctest
using Rocket

struct MySubscribable <: Subscribable{Int} end

println(Rocket.as_subscribable(MySubscribable) === SimpleSubscribableTrait{Int}())
;

# output

true

```

See also: [`SubscribableTrait`](@ref), [`SimpleSubscribableTrait`](@ref)
"""
abstract type Subscribable{T} end

"""
Super type for any scheduled subscribable object. Automatically specifies a `ScheduledSubscribableTrait` trait behavior.

# Examples
```jldoctest
using Rocket

struct MySubscribable <: ScheduledSubscribable{Int} end

println(Rocket.as_subscribable(MySubscribable) === ScheduledSubscribableTrait{Int}())
;

# output

true

```

See also: [`SubscribableTrait`](@ref), [`ScheduledSubscribableTrait`](@ref)
"""
abstract type ScheduledSubscribable{T} end

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

subscribable_extract_type(::ValidSubscribable{T}, source) where T = T
subscribable_extract_type(::InvalidSubscribable,  source)         = throw(InvalidSubscribableTraitUsageError(source))

subscribable_extract_type(::ValidSubscribable{T}, type::Type{S}) where { T, S } = T
subscribable_extract_type(::InvalidSubscribable,  type::Type{S}) where {    S } = throw(InvalidSubscribableTraitUsageError(S))

Base.eltype(source::Type{ <: S}) where { T, S <: Subscribable{T} } = T
Base.eltype(source::S)           where { T, S <: Subscribable{T} } = T

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
function subscribe!(subscribable::T, actor::S) where T where S
    return subscribable_on_subscribe!(as_subscribable(T), as_actor(S), subscribable, actor)
end

function subscribe!(subscribable::T, actor_factory::F) where T where { F <: AbstractActorFactory }
    return subscribable_on_subscribe_with_factory!(as_subscribable(T), subscribable, actor_factory)
end

subscribable_on_subscribe!(::InvalidSubscribable,   S,                     subscribable, actor)                  = throw(InvalidSubscribableTraitUsageError(subscribable))
subscribable_on_subscribe!(::ValidSubscribable{T},  ::InvalidActorTrait,   subscribable, actor) where T          = throw(InvalidActorTraitUsageError(actor))
subscribable_on_subscribe!(::ValidSubscribable{T1}, ::ValidActorTrait{T2}, subscribable, actor) where { T1, T2 } = throw(InconsistentActorWithSubscribableDataTypesError{T1, T2}(subscribable, actor))

function subscribable_on_subscribe!(S::ValidSubscribable{T1}, actor_trait::ValidActorTrait{T2}, subscribable, actor) where { T2, T1 <: T2, S }
    return subscribable_execute_subscription!(S, subscribable, actor)
end

subscribable_execute_subscription!(::SimpleSubscribableTrait,    subscribable, actor) = on_subscribe!(subscribable, actor)
subscribable_execute_subscription!(::ScheduledSubscribableTrait, subscribable, actor) = scheduled_subscription!(subscribable, actor, getscheduler(subscribable))

subscribable_on_subscribe_with_factory!(::InvalidSubscribable,  subscribable, actor_factory) = throw(InvalidSubscribableTraitUsageError(subscribable))

function subscribable_on_subscribe_with_factory!(::ValidSubscribable{L}, subscribable, actor_factory) where L
    return subscribe!(subscribable, create_actor(L, actor_factory))
end

"""
    on_subscribe!(subscribable, actor)

Each valid subscribable object have to define its own method for `on_subscribe!` function which specifies subscription logic
and has return a valid `Teardown` object.

# Arguments
- `subscribable`: Subscribable object
- `actor`: Actor object

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

See also: [`Subscribable`](@ref), [`Teardown`](@ref), [`logger`](@ref)
"""
on_subscribe!(subscribable, actor) = throw(MissingOnSubscribeImplementationError(subscribable))

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
