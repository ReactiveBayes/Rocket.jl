export sum

import Base: sum
import Base: show

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
using Rocket

source = from([ i for i in 1:42 ])
subscribe!(source |> sum(), logger())
;

# output

[LogActor] Data: 903
[LogActor] Completed

```

```jldoctest
using Rocket

source = from([ i for i in 1:42 ])
subscribe!(source |> sum(from = 97), logger())
;

# output

[LogActor] Data: 1000
[LogActor] Completed

```

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref), [`reduce`](@ref), [`logger`](@ref)
"""
sum(; from = nothing) = SumOperator(from)

struct SumOperator <: InferableOperator
    from
end

function on_call!(::Type{L}, ::Type{Union{L, Nothing}}, operator::SumOperator, source) where L
    return proxy(Union{L, Nothing}, source, SumProxy{L}(operator.from !== nothing ? convert(L, operator.from) : nothing))
end

operator_right(operator::SumOperator, ::Type{L}) where L = Union{L, Nothing}

struct SumProxy{L} <: ActorProxy
    from :: Union{L, Nothing}
end

actor_proxy!(proxy::SumProxy{L}, actor::A) where { L, A } = SumActor{L, A}(proxy.from, actor)

mutable struct SumActor{L, A} <: Actor{L}
    current :: Union{L, Nothing}
    actor   :: A
end

is_exhausted(actor::SumActor) = is_exhausted(actor.actor)

function on_next!(actor::SumActor{L}, data::L) where L
    if actor.current == nothing
        actor.current = data
    else
        actor.current = actor.current + data
    end
end

function on_error!(actor::SumActor, err)
    error!(actor.actor, err)
end

function on_complete!(actor::SumActor)
    next!(actor.actor, actor.current)
    complete!(actor.actor)
end

Base.show(io::IO, ::SumOperator)         = print(io, "SumOperator()")
Base.show(io::IO, ::SumProxy{L}) where L = print(io, "SumProxy($L)")
Base.show(io::IO, ::SumActor{L}) where L = print(io, "SumActor($L)")
