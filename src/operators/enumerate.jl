export enumerate

import Base: enumerate
import Base: show

"""
    enumerate()

Creates an enumerate operator, which converts each value emitted by the source
Observable into a tuple of its order number and the value itself.

The enumerate operator is similar to `scan(Tuple{Int, Int}, (d, c) -> (d, c[2] + 1), (0, 0))` (see [`scan`](@ref)).

# Producing

Stream of type `<: Subscribable{Tuple{Int, L}}` where `L` refers to type of source stream

# Examples
```jldoctest
using Rocket

source = from([ 0 for _ in 1:3 ])
subscribe!(source |> enumerate(), logger())
;

# output

[LogActor] Data: (1, 0)
[LogActor] Data: (2, 0)
[LogActor] Data: (3, 0)
[LogActor] Completed

```

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref), [`scan`](@ref), [`map`](@ref), [`logger`](@ref)
"""
enumerate() = EnumerateOperator()

struct EnumerateOperator <: InferableOperator end

function on_call!(::Type{L}, ::Type{Tuple{Int, L}}, operator::EnumerateOperator, source) where L
    return proxy(Tuple{Int, L}, source, EnumerateProxy{L}())
end

operator_right(operator::EnumerateOperator, ::Type{L}) where L = Tuple{Int, L}

struct EnumerateProxy{L} <: ActorProxy end

actor_proxy!(proxy::EnumerateProxy{L}, actor::A) where { L, A } = EnumerateActor{L, A}(actor, EnumerateActorProps(1))

mutable struct EnumerateActorProps
    current :: Int
end

struct EnumerateActor{L, A} <: Actor{L}
    actor :: A
    props :: EnumerateActorProps
end

getcurrent(actor::EnumerateActor)           = actor.props.current
setcurrent!(actor::EnumerateActor, current) = actor.props.current = current

function on_next!(actor::EnumerateActor{L}, data::L) where L
    current = getcurrent(actor)
    setcurrent!(actor, current + 1)
    next!(actor.actor, (current, data))
end

on_error!(actor::EnumerateActor, err) = error!(actor.actor, err)
on_complete!(actor::EnumerateActor)   = complete!(actor.actor)

Base.show(io::IO, ::EnumerateOperator)         = print(io, "EnumerateOperator()")
Base.show(io::IO, ::EnumerateProxy{L}) where L = print(io, "EnumerateProxy($L)")
Base.show(io::IO, ::EnumerateActor{L}) where L = print(io, "EnumerateActor($L)")
