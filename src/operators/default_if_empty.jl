export default_if_empty

import Base: show

"""
    default_if_empty(value::T)
    default_if_empty(callback::Function)

Creates a `default_if_empty` operator, which emits a given value if the source Observable completes
without emitting any next value, otherwise mirrors the source Observable. Optionally accepts a zero-argument callback that will be executed to generate default value.
Note: Callback function's output is always `convert`ed to the `eltype` of the original observable.

```jldoctest
using Rocket

source = completed(Int) |> default_if_empty(0)

subscribe!(source, logger())
;

# output
[LogActor] Data: 0
[LogActor] Completed
```

```jldoctest
using Rocket

source = completed(Int) |> default_if_empty(() -> 42)

subscribe!(source, logger())
;

# output
[LogActor] Data: 42
[LogActor] Completed
```

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`logger`](@ref), [`map`](@ref)
"""
default_if_empty(value_or_callback::T) where {T} =
    DefaultIfEmptyOperator{T}(value_or_callback)

struct DefaultIfEmptyOperator{T} <: InferableOperator
    value_or_callback::T
end

operator_right(::DefaultIfEmptyOperator{T}, ::Type{L}) where {L,T} = Union{L,T}
operator_right(::DefaultIfEmptyOperator{T}, ::Type{L}) where {L,T<:Function} = L

function on_call!(
    ::Type{L},
    ::Type{Union{L,T}},
    operator::DefaultIfEmptyOperator{T},
    source,
) where {L,T}
    return proxy(
        Union{L,T},
        source,
        DefaultIfEmptyProxy{Union{L,T},T}(convert(Union{L,T}, operator.value_or_callback)),
    )
end

function on_call!(
    ::Type{L},
    ::Type{L},
    operator::DefaultIfEmptyOperator{T},
    source,
) where {L,T<:Function}
    return proxy(L, source, DefaultIfEmptyProxy{L,T}(operator.value_or_callback))
end

struct DefaultIfEmptyProxy{L,T} <: ActorProxy
    default_or_callback::T
end

actor_proxy!(::Type, proxy::DefaultIfEmptyProxy{L,T}, actor::A) where {L,A,T} =
    DefaultIfEmptyActor{L,A,T}(actor, false, proxy.default_or_callback)

mutable struct DefaultIfEmptyActor{L,A,T} <: Actor{L}
    actor::A
    is_emitted::Bool
    default_or_callback::T
end

is_emmited(actor::DefaultIfEmptyActor) = actor.is_emitted
set_emmited!(actor::DefaultIfEmptyActor) = actor.is_emitted = true

release!(::DefaultIfEmptyActor{L}, callback::Function, actor) where {L} =
    next!(actor, convert(L, callback()))
release!(::DefaultIfEmptyActor{L}, default::L, actor) where {L} = next!(actor, default)

function on_next!(actor::DefaultIfEmptyActor{L}, data::L) where {L}
    set_emmited!(actor)
    next!(actor.actor, data)
end

function on_error!(actor::DefaultIfEmptyActor, err)
    set_emmited!(actor)
    error!(actor.actor, err)
end

function on_complete!(actor::DefaultIfEmptyActor)
    if !is_emmited(actor)
        set_emmited!(actor)
        release!(actor, actor.default_or_callback, actor.actor)
    end
    complete!(actor.actor)
end

Base.show(io::IO, ::DefaultIfEmptyOperator{T}) where {T} =
    print(io, "DefaultIfEmptyOperator($T)")
Base.show(io::IO, ::DefaultIfEmptyProxy{L}) where {L} = print(io, "DefaultIfEmptyProxy($L)")
Base.show(io::IO, ::DefaultIfEmptyActor{L}) where {L} = print(io, "DefaultIfEmptyActor($L)")
