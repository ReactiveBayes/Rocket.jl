export max

import Base: max
import Base: show

"""
    max(; from = nothing)

Creates a max operator, which emits a single item: the item with the largest value.

# Arguments
- `from`: optional initial maximum value, if `nothing` first item from the source will be used as initial instead

# Producing

Stream of type `<: Subscribable{Union{L, Nothing}}` where `L` refers to type of source stream

# Examples
```jldoctest
using Rocket

source = from([ i for i in 1:42 ])
subscribe!(source |> max(), logger())
;

# output

[LogActor] Data: 42
[LogActor] Completed

```

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
max(; from::D = nothing) where D = MaxOperator{D}(from)

struct MaxOperator{D} <: InferableOperator
    from :: D
end

function on_call!(::Type{L}, ::Type{Union{L, Nothing}}, operator::MaxOperator, source) where L
    return proxy(Union{L, Nothing}, source, MaxProxy(operator.from !== nothing ? convert(L, operator.from) : nothing))
end

operator_right(operator::MaxOperator, ::Type{L}) where L = Union{L, Nothing}

struct MaxProxy{D} <: ActorProxy
    from :: D
end

actor_proxy!(::Type{Union{L, Nothing}}, proxy::MaxProxy, actor::A) where { L, A } = MaxActor{L, A}(actor, proxy.from)

mutable struct MaxActor{L, A} <: Actor{L}
    actor   :: A
    current :: Union{L, Nothing}
end

getcurrent(actor::MaxActor)         = actor.current
setcurrent!(actor::MaxActor, value) = actor.current = value

function on_next!(actor::MaxActor{L}, data::L) where L
    current = getcurrent(actor)
    if current === nothing || data > current
        setcurrent!(actor, data)
    end
end

function on_error!(actor::MaxActor, err)
    error!(actor.actor, err)
end

function on_complete!(actor::MaxActor)
    next!(actor.actor, getcurrent(actor))
    complete!(actor.actor)
end

Base.show(io::IO, ::MaxOperator)         = print(io, "MaxOperator()")
Base.show(io::IO, ::MaxProxy)            = print(io, "MaxProxy()")
Base.show(io::IO, ::MaxActor{L}) where L = print(io, "MaxActor($L)")
