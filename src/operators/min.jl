export min
export MinOperator, on_call!
export MinProxy, actor_proxy!
export MinActor, on_next!, on_error!, on_complete!, is_exhausted

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
using Rx

source = from([ i for i in 1:42 ])
subscribe!(source |> min(), logger())
;

# output

[LogActor] Data: 1
[LogActor] Completed

```

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
min(; from = nothing) = MinOperator(from)

struct MinOperator <: InferableOperator
    from
end

function on_call!(::Type{L}, ::Type{Union{L, Nothing}}, operator::MinOperator, source) where L
    return proxy(Union{L, Nothing}, source, MinProxy{L}(operator.from !== nothing ? convert(L, operator.from) : nothing))
end

operator_right(operator::MinOperator, ::Type{L}) where L = Union{L, Nothing}

struct MinProxy{L} <: ActorProxy
    from :: Union{L, Nothing}
end

actor_proxy!(proxy::MinProxy{L}, actor::A) where L where A = MinActor{L, A}(proxy.from, actor)

mutable struct MinActor{L, A} <: Actor{L}
    current :: Union{L, Nothing}
    actor   :: A
end

is_exhausted(actor::MinActor) = is_exhausted(actor.actor)

function on_next!(actor::MinActor{L}, data::L) where L
    if actor.current === nothing
        actor.current = data
    else
        actor.current = data < actor.current ? data : actor.current
    end
end

function on_error!(actor::MinActor, err)
    error!(actor.actor, error)
end

function on_complete!(actor::MinActor)
    next!(actor.actor, actor.current)
    complete!(actor.actor)
end

Base.show(io::IO, operator::MinOperator)         = print(io, "MinOperator()")
Base.show(io::IO, proxy::MinProxy{L})    where L = print(io, "MinProxy($L)")
Base.show(io::IO, actor::MinActor{L})    where L = print(io, "MinActor($L)")
