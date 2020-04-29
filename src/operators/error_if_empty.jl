export error_if_empty

import Base: show

"""
    error_if_empty(err)

Creates a `error_if_empty` operator, which emits a given error if the source Observable completes
without emitting any next value, otherwise mirrors the source Observable.

```
using Rocket

source = completed(Int) |> error_if_empty("Empty")

subscribe!(source, logger())
;

# output
[LogActor] Error: Empty
```
See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`logger`](@ref), [`map`](@ref)
"""
error_if_empty(err) = ErrorIfEmptyOperator(err)

struct ErrorIfEmptyOperator <: InferableOperator
    err
end

operator_right(operator::ErrorIfEmptyOperator, ::Type{L}) where L = L

function on_call!(::Type{L}, ::Type{L}, operator::ErrorIfEmptyOperator, source) where L
    return proxy(L, source, ErrorIfEmptyProxy{L}(operator.err))
end

struct ErrorIfEmptyProxy{L} <: ActorProxy
    err
end

actor_proxy!(proxy::ErrorIfEmptyProxy{L}, actor::A) where { L, A } = ErrorIfEmptyActor{L, A}(actor, false, proxy.err)

mutable struct ErrorIfEmptyActor{L, A} <: Actor{L}
    actor      :: A
    is_emitted :: Bool
    err
end

function on_next!(actor::ErrorIfEmptyActor{L}, data::L) where L
    actor.is_emitted = true
    next!(actor.actor, data)
end

function on_error!(actor::ErrorIfEmptyActor, err)
    actor.is_emitted = true
    error!(actor.actor, err)
end

function on_complete!(actor::ErrorIfEmptyActor)
    if !actor.is_emitted
        error!(actor.actor, actor.err)
    else
        complete!(actor.actor)
    end
end

Base.show(io::IO, ::ErrorIfEmptyOperator)         = print(io, "ErrorIfEmptyOperator()")
Base.show(io::IO, ::ErrorIfEmptyProxy{L}) where L = print(io, "ErrorIfEmptyProxy($L)")
Base.show(io::IO, ::ErrorIfEmptyActor{L}) where L = print(io, "ErrorIfEmptyActor($L)")
