export sum
export SumOperator, on_call!
export SumProxy, actor_proxy!
export SumActor, on_next!, on_error!, on_complete!

import Base: sum

"""
    sum(; from = nothing)

Creates a sum operator, which applies a sum accumulator function
over the source Observable, and returns the accumulated result when the source completes,
given an optional initial value.

The `sum` operator is similar to `reduce(T, T, +)` (see [`reduce`](@ref)).

# Arguments
- `from`: optional initial accumulation value, if nothing first value will be used instead

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream

# Examples
```jldoctest
using Rx

source = from([ i for i in 1:42 ])
subscribe!(source |> sum(), LoggerActor{Int}())
;

# output

[LogActor] Data: 903
[LogActor] Completed

```

```jldoctest
using Rx

source = from([ i for i in 1:42 ])
subscribe!(source |> sum(from = 97), LoggerActor{Int}())
;

# output

[LogActor] Data: 1000
[LogActor] Completed

```

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref), [`reduce`](@ref)
"""
sum(; from = nothing) = SumOperator(from)

struct SumOperator <: InferableOperator
    from
end

function on_call!(::Type{L}, ::Type{L}, operator::SumOperator, source) where L
    return ProxyObservable{L}(source, SumProxy{L}(operator.from != nothing ? convert(L, operator.from) : nothing))
end

operator_right(operator::SumOperator, ::Type{L}) where L = L

struct SumProxy{L} <: ActorProxy
    from :: Union{L, Nothing}
end

actor_proxy!(proxy::SumProxy{L}, actor::A) where { A <: AbstractActor{L} } where L = SumActor{L, A}(proxy.from, actor)

mutable struct SumActor{L, A <: AbstractActor{L} } <: Actor{L}
    current :: Union{L, Nothing}
    actor   :: A
end

function on_next!(actor::SumActor{L, A}, data::L) where { A <: AbstractActor{L} } where L
    if actor.current == nothing
        actor.current = data
    else
        actor.current = actor.current + data
    end
end

function on_error!(actor::SumActor{L, A}, err) where { A <: AbstractActor{L} } where L
    error!(actor.actor, err)
end

function on_complete!(actor::SumActor{L, A}) where { A <: AbstractActor{L} } where L
    next!(actor.actor, actor.current)
    complete!(actor.actor)
end
