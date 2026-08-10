export accumulated

"""
    accumulated(; copy::Bool = true)

Creates an `accumulated` operator, which returns an Observable that emits the current item with all of the previous items emitted by the source Observable
in one single ordered array.

# Arguments
- `copy::Bool = true`: controls whether each emitted array is an independent copy of the
  internal accumulator (see the note below). Defaults to `true`.

# Producing

Stream of type `<: Subscribable{Vector{L}}` where `L` refers to the type of the source stream

# Examples
```jldoctest
using Rocket

source = from([ 1, 2, 3 ])
subscribe!(source |> accumulated(), logger())
;

# output

[LogActor] Data: [1]
[LogActor] Data: [1, 2]
[LogActor] Data: [1, 2, 3]
[LogActor] Completed

```

```jldoctest
using Rocket

source = of(1)
subscribe!(source |> accumulated(), logger())
;

# output

[LogActor] Data: [1]
[LogActor] Completed
```

!!! note
    With the default `copy = true` every emission is an independent snapshot, so a
    downstream actor may safely retain the emitted arrays. With `copy = false` the operator
    forwards its **live internal accumulator** by reference on every emission — this avoids
    per-emission allocation (useful in hot paths) but means the returned array **must not be
    mutated or retained**: it keeps growing in place, so any previously-emitted array observed
    later will reflect the latest accumulated state rather than the snapshot at emission time.

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
accumulated(; copy::Bool = true) = AccumulatedOperator(copy)

struct AccumulatedOperator <: InferableOperator
    copy::Bool
end

function on_call!(
    ::Type{L},
    ::Type{Vector{L}},
    operator::AccumulatedOperator,
    source,
) where {L}
    return proxy(Vector{L}, source, AccumulatedProxy(operator.copy))
end

operator_right(::AccumulatedOperator, ::Type{L}) where {L} = Vector{L}

struct AccumulatedProxy <: ActorProxy
    copy::Bool
end

actor_proxy!(::Type{Vector{L}}, proxy::AccumulatedProxy, actor::A) where {L,A} =
    AccumulatedActor{L,A}(Vector{L}(), actor, proxy.copy)

struct AccumulatedActor{L,A} <: Actor{L}
    values::Vector{L}
    actor::A
    copy::Bool
end

on_next!(actor::AccumulatedActor{L}, data::L) where {L} = begin
    push!(actor.values, data)
    next!(actor.actor, actor.copy ? copy(actor.values) : actor.values)
end
on_error!(actor::AccumulatedActor, err) = error!(actor.actor, err)
on_complete!(actor::AccumulatedActor) = complete!(actor.actor)

Base.show(io::IO, ::AccumulatedOperator) = print(io, "AccumulatedOperator()")
Base.show(io::IO, ::AccumulatedProxy) = print(io, "AccumulatedProxy()")
Base.show(io::IO, ::AccumulatedActor{L}) where {L} = print(io, "AccumulatedActor($L)")
