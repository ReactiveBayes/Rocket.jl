export default_if_empty

import Base: show

"""
    default_if_empty(value::T)

Creates a `default_if_empty` operator, which emits a given value if the source Observable completes
without emitting any next value, otherwise mirrors the source Observable.

```
using Rocket

source = completed(Int) |> default_if_empty(0)

subscribe!(source, logger())
;

# output
[LogActor] Data: 0
[LogActor] Completed
```
See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`logger`](@ref), [`map`](@ref)
"""
default_if_empty(value::T) where T = DefaultIfEmptyOperator{T}(value)

struct DefaultIfEmptyOperator{T} <: InferableOperator
    value :: T
end

operator_right(operator::DefaultIfEmptyOperator{T}, ::Type{L}) where { L, T } = Union{L, T}

function on_call!(::Type{L}, ::Type{Union{L, T}}, operator::DefaultIfEmptyOperator{T}, source) where { L, T }
    return proxy(Union{L, T}, source, DefaultIfEmptyProxy{Union{L, T}}(convert(Union{L, T}, operator.value)))
end

struct DefaultIfEmptyProxy{L} <: ActorProxy
    default :: L
end

actor_proxy!(proxy::DefaultIfEmptyProxy{L}, actor::A) where { L, A } = DefaultIfEmptyActor{L, A}(actor, false, proxy.default)

mutable struct DefaultIfEmptyActor{L, A} <: Actor{L}
    actor      :: A
    is_emitted :: Bool
    default    :: L
end

is_exhausted(actor::DefaultIfEmptyActor) = is_exhausted(actor.actor)

function on_next!(actor::DefaultIfEmptyActor{L}, data::L) where L
    actor.is_emitted = true
    next!(actor.actor, data)
end

function on_error!(actor::DefaultIfEmptyActor, err)
    actor.is_emitted = true
    error!(actor.actor, err)
end

function on_complete!(actor::DefaultIfEmptyActor)
    if !actor.is_emitted
        next!(actor.actor, actor.default)
    end
    complete!(actor.actor)
end

Base.show(io::IO, operator::DefaultIfEmptyOperator{T}) where T = print(io, "DefaultIfEmptyOperator($T)")
Base.show(io::IO, proxy::DefaultIfEmptyProxy{L})       where L = print(io, "DefaultIfEmptyProxy($L)")
Base.show(io::IO, actor::DefaultIfEmptyActor{L})       where L = print(io, "DefaultIfEmptyActor($L)")
