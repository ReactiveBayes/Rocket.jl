export SubscribableTrait, ValidSubscribable, InvalidSubscribable
export Subscribable, as_subscribable
export subscribe!, on_subscribe!

"""
Abstract type for all possible subscribable traits

See also: [`ValidSubscribable`](@ref), [`InvalidSubscribable`](@ref)
"""
abstract type SubscribableTrait{T} end

"""
Valid subscription trait behavior. Valid subscribable can be used in subscribe! fucntion.

See also: [`SubscribableTrait`](@ref), [`Subscribable`](@ref)
"""
struct ValidSubscribable{T} <: SubscribableTrait{T} end

"""
Default subscription trait behavior for all types. Invalid subscribable cannot be used in subscribe! function, doing so will throw an error.

See also: [`SubscribableTrait`](@ref), [`subscribe!`](@ref)
"""
struct InvalidSubscribable  <: SubscribableTrait{Nothing} end

"""
Super type for any subscribable object. Automatically specifies a `ValidSubscribable` trait behavior.

# Examples
```jldoctest
using Rx

struct MySubscribable <: Subscribable{Int} end

println(Rx.as_subscribable(MySubscribable) === ValidSubscribable{Int}())
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
using Rx

struct MyArbitraryType end
Rx.as_subscribable(::Type{<:MyArbitraryType}) = ValidSubscribable{Int}()

println(as_subscribable(MyArbitraryType) ===ValidSubscribable{Int}())
;

# output

true

```

"""
as_subscribable(::Type)                            = InvalidSubscribable()
as_subscribable(::Type{<:Subscribable{T}}) where T = ValidSubscribable{T}()

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
using Rx

source = from((1, 2, 3))
subscribe!(source, LoggerActor{Int}())
;

# output

[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Data: 3
[LogActor] Completed
```

```jldoctest
using Rx

source = from((1, 2, 3))
subscribe!(source, 1)
;

# output

ERROR: Type Int64 is not a valid actor type.
[...]
```

```jldoctest
using Rx

source = from((1, 2, 3))
subscribe!(1, LoggerActor{Int}());
;

# output

ERROR: Type Int64 is not a valid subscribable type.
[...]
```
"""
function subscribe!(subscribable::T, actor::S) where T where S
    subscribable_on_subscribe!(as_subscribable(T), as_actor(S), subscribable, actor)
end

# TODO: Add a posibility for actors to be a supertype of source data type, for example
# source <: Subscribable{L}
# actor  <: Actor{Union{L, Nothing}}

subscribable_on_subscribe!(::InvalidSubscribable,   S,                     subscribable, actor)                   = error("Type $(typeof(subscribable)) is not a valid subscribable type. \nConsider extending your subscribable with Subscribable{T} abstract type.")
subscribable_on_subscribe!(::ValidSubscribable,     ::UndefinedActorTrait, subscribable, actor)                   = error("Type $(typeof(actor)) is not a valid actor type. \nConsider extending your actor with one of the abstract actor types <: (Actor{T}, NextActor{T}, ErrorActor{T}, CompletionActor{T}).")
subscribable_on_subscribe!(::ValidSubscribable{T1}, ::ActorTrait{T2},      subscribable, actor) where T1 where T2 = error("Actor of type $(typeof(actor)) expects data to be of type $(T2), while subscribable of type $(typeof(subscribable)) produces data of type $(T1).")
subscribable_on_subscribe!(::ValidSubscribable{T},  ::ActorTrait{T},       subscribable, actor) where T           = on_subscribe!(subscribable, actor)

"""
    on_subscribe!(subscribable, actor)

Each valid subscribable object have to define its own method for `on_subscribe!` function which specifies subscription logic
and has return a valid `Teardown` object.

# Arguments
- `subscribable`: Subscribable object
- `actor`: Actor object

# Examples

```jldoctest
using Rx

struct MySubscribable <: Subscribable{Int} end

function Rx.on_subscribe!(subscribable::MySubscribable, actor::A) where { A <: AbstractActor{Int} }
    next!(actor, 0)
    complete!(actor)
    return VoidTeardown()
end

subscribe!(MySubscribable(), LoggerActor{Int}())
;

# output

[LogActor] Data: 0
[LogActor] Completed
```

See also: [`Subscribable`](@ref), [`Teardown`](@ref)
"""
on_subscribe!(subscribable, actor) = error("You probably forgot to implement on_subscribe!(subscribable::$(typeof(subscribable)), actor).")
