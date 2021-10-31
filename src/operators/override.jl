export override, OverrideHandler

import Base: show

"""
    OverrideHandler(::Type{T}) where T
    OverrideHandler(value::T)  where T

Handler used in `substitute` operator.

See also: [`substitute`](@ref)
"""
mutable struct OverrideHandler{T}
    value :: Union{Nothing, T}
end

OverrideHandler(::Type{T}) where T = OverrideHandler{T}(nothing)
OverrideHandler(value::T)  where T = OverrideHandler{T}(value)

setvalue!(handler::OverrideHandler, value) = handler.value = value
getvalue(handler::OverrideHandler)         = handler.value

"""
    override(handler::OverrideHandler)

Creates an override operator that overrides each emission from source observable with value 
provided in `handler`. If handler contains `nothing` source observable emits as usual.
For constant override see [`map_to`](@ref). Use `Rocket.setvalue!` to set new value for `handler`.

# Producing 

Stream of type `<: Subscribable{Union{L, T}}` where `L` refers to the type of source stream and `T` referes to the type of handler's value

# Examples 

```jldoctest
using Rocket 

subject = Subject(Int)
handler = OverrideHandler(-1)

source = subject |> override(handler)

subscription = subscribe!(source, logger())

next!(subject, 1)
next!(subject, 2)

Rocket.setvalue!(handler, nothing)

next!(subject, 3)
next!(subject, 4)

Rocket.setvalue!(handler, -2)

next!(subject, 5)
next!(subject, 6)

unsubscribe!(subscription)

# output
[LogActor] Data: -1
[LogActor] Data: -1
[LogActor] Data: 3
[LogActor] Data: 4
[LogActor] Data: -2
[LogActor] Data: -2
```

See also: [`OverrideHandler`](@ref)
"""
override(handler::OverrideHandler{T}) where T = OverrideOperator{T}(handler)

struct OverrideOperator{T} <: InferableOperator 
    handler :: OverrideHandler{T}
end

operator_right(::OverrideOperator{T}, ::Type{L}) where { T, L } = Union{T, L}

function on_call!(::Type{L}, ::Type{Union{L, T}}, operator::OverrideOperator{T}, source) where { L, T }
    return proxy(Union{L, T}, source, OverrideProxy{T}(operator.handler))
end

struct OverrideProxy{T} <: ActorProxy 
    handler :: OverrideHandler{T}
end

actor_proxy!(::Type{L}, proxy::OverrideProxy{T}, actor::A) where { L, T, A } = OverrideActor{L, T, A}(proxy.handler, actor)

struct OverrideActor{L, T, A} <: Actor{L}
    handler :: OverrideHandler{T}
    actor   :: A
end

function on_next!(actor::OverrideActor{L}, data::L) where L 
    override_value = getvalue(actor.handler)
    if override_value !== nothing 
        next!(actor.actor, override_value)
    else
        next!(actor.actor, data)
    end
end

on_error!(actor::OverrideActor, err) = error!(actor.actor, err)
on_complete!(actor::OverrideActor)   = complete!(actor.actor)

Base.show(io::IO, ::OverrideOperator)          = print(io, "OverrideOperator()")
Base.show(io::IO, ::OverrideProxy)             = print(io, "OverrideProxy()")
Base.show(io::IO, ::OverrideActor{L})  where L = print(io, "OverrideActor($L)")
