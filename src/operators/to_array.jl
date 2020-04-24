export to_array

import Base: show

"""
    to_array()

Creates a `to_array` operator, which reduces all values into a single array and returns this result when the source completes.

# Producing

Stream of type `<: Subscribable{Vector{L}}` where `L` refers to type of source stream

# Examples
```jldoctest
using Rocket

source = from([ 1, 2, 3 ])
subscribe!(source |> to_array(), logger())
;

# output

[LogActor] Data: [1, 2, 3]
[LogActor] Completed

```

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
to_array() = ToArrayOperator()

struct ToArrayOperator <: InferableOperator end

function on_call!(::Type{L}, ::Type{Vector{L}}, operator::ToArrayOperator, source) where L
    return proxy(Vector{L}, source, ToArrayProxy{L}())
end

operator_right(operator::ToArrayOperator, ::Type{L}) where L = Vector{L}

struct ToArrayProxy{L} <: ActorProxy end

actor_proxy!(proxy::ToArrayProxy{L}, actor::A) where { L, A } = ToArrayActor{L, A}(actor)

struct ToArrayActor{L, A} <: Actor{L}
    values :: Vector{L}
    actor  :: A

    ToArrayActor{L, A}(actor::A) where { L, A } = new(Vector{L}(), actor)
end

is_exhausted(actor::ToArrayActor) = is_exhausted(actor.actor)

on_next!(actor::ToArrayActor, data::L) where L = push!(actor.values, data)
on_error!(actor::ToArrayActor, err)            = error!(actor.actor, err)

function on_complete!(actor::ToArrayActor)
    next!(actor.actor, actor.values)
    complete!(actor.actor)
end

Base.show(io::IO, ::ToArrayOperator)         = print(io, "ToArrayOperator()")
Base.show(io::IO, ::ToArrayProxy{L}) where L = print(io, "ToArrayProxy($L)")
Base.show(io::IO, ::ToArrayActor{L}) where L = print(io, "ToArrayActor($L)")
