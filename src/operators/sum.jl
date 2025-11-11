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
sum(; from::D = nothing) where {D} = SumOperator{D}(from)

struct SumOperator{D} <: InferableOperator
    from::D
end

function on_call!(
    ::Type{L},
    ::Type{Union{L,Nothing}},
    operator::SumOperator,
    source,
) where {L}
    return proxy(
        Union{L,Nothing},
        source,
        SumProxy(operator.from !== nothing ? convert(L, operator.from) : nothing),
    )
end

operator_right(operator::SumOperator, ::Type{L}) where {L} = Union{L,Nothing}

struct SumProxy{D} <: ActorProxy
    from::D
end

actor_proxy!(::Type{Union{L,Nothing}}, proxy::SumProxy, actor::A) where {L,A} =
    SumActor{L,A}(actor, proxy.from)

mutable struct SumActor{L,A} <: Actor{L}
    actor::A
    current::Union{L,Nothing}
end

getcurrent(actor::SumActor) = actor.current
setcurrent!(actor::SumActor, value) = actor.current = value

function on_next!(actor::SumActor{L}, data::L) where {L}
    current = getcurrent(actor)
    if current === nothing
        setcurrent!(actor, data)
    else
        setcurrent!(actor, current + data)
    end
end

function on_error!(actor::SumActor, err)
    error!(actor.actor, err)
end

function on_complete!(actor::SumActor)
    next!(actor.actor, getcurrent(actor))
    complete!(actor.actor)
end

Base.show(io::IO, ::SumOperator) = print(io, "SumOperator()")
Base.show(io::IO, ::SumProxy) = print(io, "SumProxy()")
Base.show(io::IO, ::SumActor{L}) where {L} = print(io, "SumActor($L)")
