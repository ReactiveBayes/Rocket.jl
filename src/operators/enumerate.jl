export enumerate
export EnumerateOperator, on_call!, operator_right
export EnumerateProxy, actor_proxy!
export EnumerateActor, on_next!, on_error!, on_complete!, is_exhausted

import Base: enumerate

"""
    enumerate()

Creates an enumerate operator, which converts each value emitted by the source
Observable into a tuple of its order number and the value itself.

The enumerate operator is similar to
`scan(Tuple{Int, Int}, (d, c) -> (d, c[2] + 1), (0, 0))`
(see [`scan`](@ref)).

# Producing

Stream of type `<: Subscribable{Tuple{L, Int}}` where `L` refers to type of source stream

# Examples
```jldoctest
using Rx

source = from([ i for i in 1:3 ])
subscribe!(source |> enumerate(), LoggerActor{Tuple{Int, Int}}())
;

# output

[LogActor] Data: (1, 1)
[LogActor] Data: (2, 2)
[LogActor] Data: (3, 3)
[LogActor] Completed

```

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref), [`scan`](@ref), [`map`](@ref)
"""
enumerate() = EnumerateOperator()

struct EnumerateOperator <: InferableOperator end

function on_call!(::Type{L}, ::Type{Tuple{L, Int}}, operator::EnumerateOperator, source) where L
    return ProxyObservable{Tuple{L, Int}}(source, EnumerateProxy{L}())
end

operator_right(operator::EnumerateOperator, ::Type{L}) where L = Tuple{L, Int}

struct EnumerateProxy{L} <: ActorProxy end

actor_proxy!(proxy::EnumerateProxy{L}, actor) where L = EnumerateActor{L}(1, actor)

mutable struct EnumerateActor{L} <: Actor{L}
    current :: Int
    actor
end

is_exhausted(actor::EnumerateActor) = is_exhausted(actor.actor)

function on_next!(c::EnumerateActor{L}, data::L) where L
    current = c.current
    c.current += 1
    next!(c.actor, (data, current))
end

on_error!(c::EnumerateActor, err) = error!(c.actor, err)
on_complete!(c::EnumerateActor)   = complete!(c.actor)
