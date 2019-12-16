export sum
export SumOperator, on_call!
export SumProxy, actor_proxy!
export SumActor, on_next!, on_error!, on_complete!

import Base: sum

"""
    sum(::Type{T}, from::R = zero(T)) where T

Creates a sum operator, which applies a sum accumulator function
over the source Observable, and returns the accumulated result when the source completes,
given an optional initial value.

The `sum` operator is similar to `reduce(T, T, +)` (see [`reduce`](@ref)).

# Arguments
- `::Type{T}`: the type of data of source
- `from::R`: optional initial accumulation value

# Examples
```jldoctest
using Rx

source = from([ i for i in 1:42 ])
subscribe!(source |> sum(Int), LoggerActor{Int}())
;

# output

[LogActor] Data: 903
[LogActor] Completed

```

See also: [`Operator`](@ref), ['ProxyObservable'](@ref), [`reduce`](@ref)
"""
sum(::Type{T}, from = zero(T)) where T = SumOperator{T}(from)

struct SumOperator{T} <: Operator{T, T}
    from :: T
end

function on_call!(operator::SumOperator{T}, source::S) where { S <: Subscribable{T} } where T
    return ProxyObservable{T}(source, SumProxy{T}(operator.from))
end

struct SumProxy{T} <: ActorProxy
    from :: T
end

actor_proxy!(proxy::SumProxy{T}, actor::A) where { A <: AbstractActor{T} } where T = SumActor{T}(proxy.from, actor)

mutable struct SumActor{T} <: Actor{T}
    current :: T
    actor
end

function on_next!(actor::SumActor{T}, data::T) where T
    actor.current = actor.current + data
end

on_error!(actor::SumActor{T}, error) where T = error!(actor.actor, error)

function on_complete!(actor::SumActor{T}) where T
    next!(actor.actor, actor.current)
    complete!(actor.actor)
end
