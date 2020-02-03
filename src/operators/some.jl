export some

import Base: show

"""
    some()

Creates a some operator, which filters out `nothing` items by the source Observable by emitting only
those that not equal to `nothing`.

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream `<: Subscribable{Union{L, Nothing}}`

# Examples
```jldoctest
using Rocket

source = from([ 1, nothing, 3 ])
subscribe!(source |> some(), logger())
;

# output

[LogActor] Data: 1
[LogActor] Data: 3
[LogActor] Completed

```

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref), [`max`](@ref), [`min`](@ref), [`logger`](@ref)
"""
some() = SomeOperator()

struct SomeOperator <: InferableOperator end

function on_call!(::Type{Union{L, Nothing}}, ::Type{L}, operator::SomeOperator, source) where L
    return proxy(L, source, SomeProxy{L}())
end

operator_right(operator::SomeOperator, ::Type{Union{L, Nothing}}) where L = L

struct SomeProxy{L} <: ActorProxy end

actor_proxy!(proxy::SomeProxy{L}, actor::A) where L where A = SomeActor{L, A}(actor)

struct SomeActor{L, A} <: Actor{Union{L, Nothing}}
    actor :: A
end

is_exhausted(actor::SomeActor) = is_exhausted(actor.actor)

function on_next!(f::SomeActor{L}, data::Union{L, Nothing}) where L
    if data !== nothing
        next!(f.actor, data)
    end
end

on_error!(f::SomeActor, err) = error!(f.actor, err)
on_complete!(f::SomeActor)   = complete!(f.actor)

Base.show(io::IO, operator::SomeOperator)         = print(io, "SomeOperator()")
Base.show(io::IO, proxy::SomeProxy{L})    where L = print(io, "SomeProxy($L)")
Base.show(io::IO, actor::SomeActor{L})    where L = print(io, "SomeActor($L)")
