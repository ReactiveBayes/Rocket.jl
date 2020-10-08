export SubscribableTrait, SimpleSubscribableTrait, ScheduledSubscribableTrait, InvalidSubscribableTrait
export AbstractSubscribable, Subscribable, ScheduledSubscribable, as_subscribable
export subscribe!, on_subscribe!
export subscribable_extract_type

export InvalidSubscribableTraitUsageError, InconsistentActorWithSubscribableDataTypesError
export MissingOnSubscribeImplementationError, MissingOnScheduledSubscribeImplementationError

import Base: show, showerror
import Base: eltype

"""
Abstract type for all possible subscribable traits

See also: [`SimpleSubscribableTrait`](@ref), [`ScheduledSubscribableTrait`](@ref), [`InvalidSubscribableTrait`](@ref)
"""
abstract type SubscribableTrait end

"""
Simple subscribable trait behavior. Simple subscribable can be used in subscribe! function and just executes `on_subscribe!` method for provided subscribable.
`SimpleSubscribableTrait` is a subtype of `SubscribableTrait`.

See also: [`SubscribableTrait`](@ref), [`Subscribable`](@ref), [`subscribe!`](@ref), [`on_subscribe!`](@ref)
"""
struct SimpleSubscribableTrait{T} <: SubscribableTrait end

"""
Scheduled subscribable trait behavior. Scheduled subscribable can be used in subscribe! function and executes `on_subscribe!` method for provided subscribable with custom scheduling.
`ScheduledSubscribableTrait` is a subtype of `SubscribableTrait`.

See also: [`SubscribableTrait`](@ref), [`ScheduledSubscribable`](@ref), [`subscribe!`](@ref), [`on_subscribe!`](@ref)
"""
struct ScheduledSubscribableTrait{T} <: SubscribableTrait end

"""
Default subscribable trait behavior for all types. Invalid subscribable cannot be used in subscribe! function, doing so will throw an error.
`InvalidSubscribableTrait` is a subtype of `SubscribableTrait`.

See also: [`SubscribableTrait`](@ref), [`subscribe!`](@ref)
"""
struct InvalidSubscribableTrait <: SubscribableTrait end

"""
Supertype type for `Subscribable` and `ScheduledSubscribable` types.

See also: [`Subscribable`](@ref), [`ScheduledSubscribable`](@ref)
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

See also: [`SubscribableTrait`](@ref), [`SimpleSubscribableTrait`](@ref)
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

See also: [`SubscribableTrait`](@ref), [`ScheduledSubscribableTrait`](@ref)
"""
abstract type ScheduledSubscribable{T} <: AbstractSubscribable{T} end

"""
    as_subscribable(any)

This function checks subscribable trait behavior specification. Can be used explicitly to specify subscribable trait behavior for any object.

See also: [`SubscribableTrait`](@ref)
"""
as_subscribable(::Type)                                        = InvalidSubscribableTrait()
as_subscribable(::Type{ <: Subscribable{T} })          where T = SimpleSubscribableTrait{T}()
as_subscribable(::Type{ <: ScheduledSubscribable{T} }) where T = ScheduledSubscribableTrait{T}()
as_subscribable(::O)                                   where O = as_subscribable(O)

subscribable_extract_type(::Type{S}) where S = subscribable_extract_type(as_subscribable(S), S)
subscribable_extract_type(::S)       where S = subscribable_extract_type(S)

subscribable_extract_type(::SimpleSubscribableTrait{T},    _) where T = T
subscribable_extract_type(::ScheduledSubscribableTrait{T}, _) where T = T
subscribable_extract_type(::InvalidSubscribableTrait, source)         = throw(InvalidSubscribableTraitUsageError(source))

Base.eltype(source::Subscribable)           = subscribable_extract_type(source)
Base.eltype(source::ScheduledSubscribable)  = subscribable_extract_type(source)

Base.eltype(source::Type{ <: Subscribable })          = subscribable_extract_type(source)
Base.eltype(source::Type{ <: ScheduledSubscribable }) = subscribable_extract_type(source)

"""
    subscribe!(subscribable::T, actor::S)   where { T, S }
    subscribe!(subscribable::T, factory::F) where { T, F <: AbstractActorFactory }

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
subscribe!(subscribable::T, actor::S) where { T, S } = check_on_subscribe!(as_subscribable(T), as_actor(S), subscribable, actor)

# Specialised methods for built-in default subscribable and actor types
subscribe!(subscribable::Subscribable{T1},          actor::Actor{T2}) where { T2, T1 <: T2 } = on_subscribe!(subscribable, actor)
subscribe!(subscribable::ScheduledSubscribable{T1}, actor::Actor{T2}) where { T2, T1 <: T2 } = scheduled_subscription!(subscribable, actor, makeinstance(T1, getscheduler(subscribable)))

# We don't use an abstract types here and dispatch on all possible combinations of types because of the issue #37045 JuliaLang/julia
# https://github.com/JuliaLang/julia/issues/37045
check_on_subscribe!(::InvalidSubscribableTrait,       _,                          subscribable, actor)                  = throw(InvalidSubscribableTraitUsageError(subscribable))
check_on_subscribe!(::SimpleSubscribableTrait,        ::InvalidActorTrait,        subscribable, actor)                  = throw(InvalidActorTraitUsageError(actor))
check_on_subscribe!(::ScheduledSubscribableTrait,     ::InvalidActorTrait,        subscribable, actor)                  = throw(InvalidActorTraitUsageError(actor))
check_on_subscribe!(::SimpleSubscribableTrait{T1},    ::BaseActorTrait{T2},       subscribable, actor) where { T1, T2 } = throw(InconsistentActorWithSubscribableDataTypesError{T1, T2}(subscribable, actor))
check_on_subscribe!(::SimpleSubscribableTrait{T1},    ::NextActorTrait{T2},       subscribable, actor) where { T1, T2 } = throw(InconsistentActorWithSubscribableDataTypesError{T1, T2}(subscribable, actor))
check_on_subscribe!(::SimpleSubscribableTrait{T1},    ::ErrorActorTrait{T2},      subscribable, actor) where { T1, T2 } = throw(InconsistentActorWithSubscribableDataTypesError{T1, T2}(subscribable, actor))
check_on_subscribe!(::SimpleSubscribableTrait{T1},    ::CompletionActorTrait{T2}, subscribable, actor) where { T1, T2 } = throw(InconsistentActorWithSubscribableDataTypesError{T1, T2}(subscribable, actor))
check_on_subscribe!(::ScheduledSubscribableTrait{T1}, ::BaseActorTrait{T2},       subscribable, actor) where { T1, T2 } = throw(InconsistentActorWithSubscribableDataTypesError{T1, T2}(subscribable, actor))
check_on_subscribe!(::ScheduledSubscribableTrait{T1}, ::NextActorTrait{T2},       subscribable, actor) where { T1, T2 } = throw(InconsistentActorWithSubscribableDataTypesError{T1, T2}(subscribable, actor))
check_on_subscribe!(::ScheduledSubscribableTrait{T1}, ::ErrorActorTrait{T2},      subscribable, actor) where { T1, T2 } = throw(InconsistentActorWithSubscribableDataTypesError{T1, T2}(subscribable, actor))
check_on_subscribe!(::ScheduledSubscribableTrait{T1}, ::CompletionActorTrait{T2}, subscribable, actor) where { T1, T2 } = throw(InconsistentActorWithSubscribableDataTypesError{T1, T2}(subscribable, actor))

check_on_subscribe!(::SimpleSubscribableTrait{T1}, ::BaseActorTrait{T2},       subscribable, actor) where { T2, T1 <: T2 } = on_subscribe!(subscribable, actor)
check_on_subscribe!(::SimpleSubscribableTrait{T1}, ::NextActorTrait{T2},       subscribable, actor) where { T2, T1 <: T2 } = on_subscribe!(subscribable, actor)
check_on_subscribe!(::SimpleSubscribableTrait{T1}, ::ErrorActorTrait{T2},      subscribable, actor) where { T2, T1 <: T2 } = on_subscribe!(subscribable, actor)
check_on_subscribe!(::SimpleSubscribableTrait{T1}, ::CompletionActorTrait{T2}, subscribable, actor) where { T2, T1 <: T2 } = on_subscribe!(subscribable, actor)

check_on_subscribe!(::ScheduledSubscribableTrait{T1}, ::BaseActorTrait{T2},       subscribable, actor) where { T2, T1 <: T2 } = scheduled_subscription!(subscribable, actor, makeinstance(T1, getscheduler(subscribable)))
check_on_subscribe!(::ScheduledSubscribableTrait{T1}, ::NextActorTrait{T2},       subscribable, actor) where { T2, T1 <: T2 } = scheduled_subscription!(subscribable, actor, makeinstance(T1, getscheduler(subscribable)))
check_on_subscribe!(::ScheduledSubscribableTrait{T1}, ::ErrorActorTrait{T2},      subscribable, actor) where { T2, T1 <: T2 } = scheduled_subscription!(subscribable, actor, makeinstance(T1, getscheduler(subscribable)))
check_on_subscribe!(::ScheduledSubscribableTrait{T1}, ::CompletionActorTrait{T2}, subscribable, actor) where { T2, T1 <: T2 } = scheduled_subscription!(subscribable, actor, makeinstance(T1, getscheduler(subscribable)))

function subscribe!(subscribable::T, factory::F) where { T, F <: AbstractActorFactory }
    return check_on_subscribe_with_factory!(as_subscribable(T), subscribable, factory)
end

check_on_subscribe_with_factory!(::InvalidSubscribableTrait,      subscribable, factory)         = throw(InvalidSubscribableTraitUsageError(subscribable))
check_on_subscribe_with_factory!(::SimpleSubscribableTrait{L},    subscribable, factory) where L = subscribe!(subscribable, create_actor(L, factory))
check_on_subscribe_with_factory!(::ScheduledSubscribableTrait{L}, subscribable, factory) where L = subscribe!(subscribable, create_actor(L, factory))

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
    return voidTeardown
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

Rocket.getscheduler(::MyScheduledSubscribable) = AsapScheduler()

function Rocket.on_subscribe!(subscribable::MyScheduledSubscribable, actor, scheduler)
    next!(actor, 0, scheduler)
    complete!(actor, scheduler)
    return voidTeardown
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

function Base.showerror(io::IO, err::InvalidSubscribableTraitUsageError)
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

function Base.showerror(io::IO, err::InconsistentActorWithSubscribableDataTypesError{T1, T2}) where T1 where T2
    print(io, "Actor of type $(typeof(err.actor)) expects data to be of type $(T2), while subscribable of type $(typeof(err.subscribable)) produces data of type $(T1).")
end

"""
This error will be thrown if Julia cannot find specific method of 'on_subscribe!()' function for given subscribable and actor

See also: [`on_subscribe!`](@ref)
"""
struct MissingOnSubscribeImplementationError
    subscribable
end

function Base.showerror(io::IO, err::MissingOnSubscribeImplementationError)
    print(io, "You probably forgot to implement on_subscribe!(subscribable::$(typeof(err.subscribable)), actor).")
end

"""
This error will be thrown if Julia cannot find specific method of 'on_subscribe!()' function for given subscribable, actor and scheduler

See also: [`on_subscribe!`](@ref)
"""
struct MissingOnScheduledSubscribeImplementationError
    subscribable
end

function Base.showerror(io::IO, err::MissingOnScheduledSubscribeImplementationError)
    print(io, "You probably forgot to implement on_subscribe!(subscribable::$(typeof(err.subscribable)), actor, scheduler).")
end
