export accumulated

"""
    accumulated()

Creates an `accumulated` operator, which returns an Observable that emits the current item with all of the previous items emitted by the source Observable 
in one single ordered array.

# Producing

Stream of type `<: Subscribable{Vector{L}}` where `L` refers to type of source stream

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

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
accumulated() = AccumulatedOperator()

struct AccumulatedOperator <: InferableOperator end

function on_call!(
    ::Type{L},
    ::Type{Vector{L}},
    operator::AccumulatedOperator,
    source,
) where {L}
    return proxy(Vector{L}, source, AccumulatedProxy())
end

operator_right(::AccumulatedOperator, ::Type{L}) where {L} = Vector{L}

struct AccumulatedProxy <: ActorProxy end

actor_proxy!(::Type{Vector{L}}, proxy::AccumulatedProxy, actor::A) where {L,A} =
    AccumulatedActor{L,A}(Vector{L}(), actor)

struct AccumulatedActor{L,A} <: Actor{L}
    values::Vector{L}
    actor::A
end

on_next!(actor::AccumulatedActor{L}, data::L) where {L} = begin
    push!(actor.values, data);
    next!(actor.actor, actor.values)
end
on_error!(actor::AccumulatedActor, err) = error!(actor.actor, err)
on_complete!(actor::AccumulatedActor) = complete!(actor.actor)

Base.show(io::IO, ::AccumulatedOperator) = print(io, "AccumulatedOperator()")
Base.show(io::IO, ::AccumulatedProxy) = print(io, "AccumulatedProxy()")
Base.show(io::IO, ::AccumulatedActor{L}) where {L} = print(io, "AccumulatedActor($L)")
