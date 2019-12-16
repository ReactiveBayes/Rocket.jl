export enumerate
export EnumerateOperator, on_call!
export EnumerateProxy, actor_proxy!
export EnumerateActor, on_next!, on_error!, on_complete!

import Base: enumerate

"""
    enumerate(::Type{T}) where T

Creates an enumerate operator, which converts each value emitted by the source
Observable into a tuple of its order number and the value itself.

The enumerate operator is similar to
`scan(Int, Tuple{Int, Int}, (d, c) -> (d, c[2] + 1), (0, 0))`
(see [`scan`](@ref)).

# Arguments
- `::Type{T}`: the type of data of source

# Examples
```jldoctest
using Rx

source = from([ i for i in 1:3 ])
subscribe!(source |> enumerate(Int), LoggerActor{Tuple{Int, Int}}())
;

# output

[LogActor] Data: (1, 1)
[LogActor] Data: (2, 2)
[LogActor] Data: (3, 3)
[LogActor] Completed

```

See also: [`Operator`](@ref), ['ProxyObservable'](@ref), [`map`](@ref)
"""
enumerate(::Type{T}) where T = EnumerateOperator{T}()

struct EnumerateOperator{T} <: Operator{T, Tuple{T, Int}} end

function on_call!(operator::EnumerateOperator{T}, source::S) where { S <: Subscribable{T} } where T
    return ProxyObservable{Tuple{T, Int}}(source, EnumerateProxy{T}())
end

struct EnumerateProxy{T} <: ActorProxy end

actor_proxy!(proxy::EnumerateProxy{T}, actor::A) where { A <: AbstractActor{Tuple{T, Int}} } where T = EnumerateActor{T}(actor)

mutable struct EnumerateActor{T} <: Actor{T}
    current :: Int
    actor

    EnumerateActor{T}(actor) where T = new(1, actor)
end

function on_next!(c::EnumerateActor{T}, data::T) where T
    current = c.current
    c.current += 1
    next!(c.actor, (data, current))
end

on_error!(c::EnumerateActor{T}, error) where T = error!(c.actor, error)
on_complete!(c::EnumerateActor{T})     where T = complete!(c.actor)
