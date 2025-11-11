export min

import Base: min
import Base: show

"""
    min(; from = nothing)

Creates a min operator, which emits a single item: the item with the smallest value.

# Arguments
- `from`: optional initial minimal value, if `nothing` first item from the source will be used as initial instead

# Producing

Stream of type `<: Subscribable{Union{L, Nothing}}` where `L` refers to type of source stream

# Examples
```jldoctest
using Rocket

source = from([ i for i in 1:42 ])
subscribe!(source |> min(), logger())
;

# output

[LogActor] Data: 1
[LogActor] Completed

```

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
min(; from::D = nothing) where {D} = MinOperator{D}(from)

struct MinOperator{D} <: InferableOperator
    from::D
end

function on_call!(
    ::Type{L},
    ::Type{Union{L,Nothing}},
    operator::MinOperator,
    source,
) where {L}
    return proxy(
        Union{L,Nothing},
        source,
        MinProxy(operator.from !== nothing ? convert(L, operator.from) : nothing),
    )
end

operator_right(operator::MinOperator, ::Type{L}) where {L} = Union{L,Nothing}

struct MinProxy{D} <: ActorProxy
    from::D
end

actor_proxy!(::Type{Union{L,Nothing}}, proxy::MinProxy, actor::A) where {L,A} =
    MinActor{L,A}(actor, proxy.from)

mutable struct MinActor{L,A} <: Actor{L}
    actor::A
    current::Union{L,Nothing}
end

getcurrent(actor::MinActor) = actor.current
setcurrent!(actor::MinActor, value) = actor.current = value

function on_next!(actor::MinActor{L}, data::L) where {L}
    current = getcurrent(actor)
    if current === nothing || data < current
        setcurrent!(actor, data)
    end
end

function on_error!(actor::MinActor, err)
    error!(actor.actor, err)
end

function on_complete!(actor::MinActor)
    next!(actor.actor, getcurrent(actor))
    complete!(actor.actor)
end

Base.show(io::IO, ::MinOperator) = print(io, "MinOperator()")
Base.show(io::IO, ::MinProxy) = print(io, "MinProxy()")
Base.show(io::IO, ::MinActor{L}) where {L} = print(io, "MinActor($L)")
