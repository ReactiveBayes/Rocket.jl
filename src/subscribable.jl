export SubscribableTrait, ValidSubscribable, InvalidSubscribable
export Subscribable, as_subscribable
export subscribe!, on_subscribe!
export subscribable_extract_type

export InvalidSubscribableTraitUsageError, InconsistentActorWithSubscribableDataTypesError
export MissingOnSubscribeImplementationError

import Base: show

"""
Abstract type for all possible subscribable traits

See also: [`ValidSubscribable`](@ref), [`InvalidSubscribable`](@ref)
"""
abstract type SubscribableTrait end

"""
Valid subscribable trait behavior. Valid subscribable can be used in subscribe! function.

See also: [`SubscribableTrait`](@ref), [`Subscribable`](@ref)
"""
struct ValidSubscribable{T} <: SubscribableTrait end

"""
Default subscribable trait behavior for all types. Invalid subscribable cannot be used in subscribe! function, doing so will throw an error.

See also: [`SubscribableTrait`](@ref), [`subscribe!`](@ref)
"""
struct InvalidSubscribable  <: SubscribableTrait end

"""
Super type for any subscribable object. Automatically specifies a `ValidSubscribable` trait behavior.

# Examples
```jldoctest
using Rocket

struct MySubscribable <: Subscribable{Int} end

println(Rocket.as_subscribable(MySubscribable) === ValidSubscribable{Int}())
;

# output

true

```

See also: [`SubscribableTrait`](@ref), [`ValidSubscribable`](@ref)
"""
abstract type Subscribable{T} end

"""
    as_subscribable(::Type)

This function checks subscribable trait behavior specification. Can be used explicitly to specify subscribable trait behavior for any object.

# Examples

```jldoctest
using Rocket

struct MyArbitraryType end
Rocket.as_subscribable(::Type{<:MyArbitraryType}) = ValidSubscribable{Int}()

println(as_subscribable(MyArbitraryType) ===ValidSubscribable{Int}())
;

# output
true
```

See also: [`subscribe!`](@ref)
"""
as_subscribable(::Type)                            = InvalidSubscribable()
as_subscribable(::Type{<:Subscribable{T}}) where T = ValidSubscribable{T}()

subscribable_extract_type(source::S) where S = subscribable_extract_type(as_subscribable(S), source)

subscribable_extract_type(::ValidSubscribable{T}, source) where T = T
subscribable_extract_type(::InvalidSubscribable, source)          = throw(InvalidSubscribableTraitUsageError(source))

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
    subscribable_on_subscribe!(as_subscribable(T), as_actor(S), subscribable, actor)
end

function subscribe!(subscribable::T, actor_factory::F) where T where { F <: AbstractActorFactory }
    subscribable_on_subscribe_with_factory!(as_subscribable(T), subscribable, actor_factory)
end

subscribable_on_subscribe!(::InvalidSubscribable,   S,                     subscribable, actor)                             = throw(InvalidSubscribableTraitUsageError(subscribable))
subscribable_on_subscribe!(::ValidSubscribable{T},  ::InvalidActorTrait,   subscribable, actor) where T                     = throw(InvalidActorTraitUsageError(actor))
subscribable_on_subscribe!(::ValidSubscribable{T1}, ::ValidActorTrait{T2}, subscribable, actor) where T1 where T2           = throw(InconsistentActorWithSubscribableDataTypesError{T1, T2}(subscribable, actor))
subscribable_on_subscribe!(::ValidSubscribable{T1}, ::ValidActorTrait{T2}, subscribable, actor) where { T1 <: T2 } where T2 = begin
    if !is_exhausted(actor)
        return on_subscribe!(subscribable, actor)
    else
        complete!(actor)
        return VoidTeardown()
    end
end

subscribable_on_subscribe_with_factory!(::InvalidSubscribable,  subscribable, actor_factory)         = throw(InvalidSubscribableTraitUsageError(subscribable))
subscribable_on_subscribe_with_factory!(::ValidSubscribable{L}, subscribable, actor_factory) where L = begin
    subscribe!(subscribable, create_actor(L, actor_factory))
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
