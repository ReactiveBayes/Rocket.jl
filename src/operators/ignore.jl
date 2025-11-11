export ignore

import Base: show

"""
    ignore(count::Int)

Creates a `ignore` operator, which returns an Observable
that skips the first `count` items emitted by the source Observable.

# Arguments
- `count::Int`: the number of times, items emitted by source Observable should be skipped.

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream

# Examples
```jldoctest
using Rocket

source = from(1:5)

subscribe!(source |> ignore(2), logger())
;

# output

[LogActor] Data: 3
[LogActor] Data: 4
[LogActor] Data: 5
[LogActor] Completed
```

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
ignore(count::Int) = IgnoreOperator(count)

struct IgnoreOperator <: InferableOperator
    count::Int
end

function on_call!(::Type{L}, ::Type{L}, operator::IgnoreOperator, source) where {L}
    return proxy(L, source, IgnoreProxy(operator.count))
end

operator_right(operator::IgnoreOperator, ::Type{L}) where {L} = L

struct IgnoreProxy <: ActorProxy
    count::Int
end

actor_proxy!(::Type{L}, proxy::IgnoreProxy, actor::A) where {L,A} =
    IgnoreActor{L,A}(proxy.count, actor)

mutable struct IgnoreActor{L,A} <: Actor{L}
    count::Int
    actor::A
    skipped_count::Int

    IgnoreActor{L,A}(count::Int, actor::A) where {L,A} = new(count, actor, 0)
end

function on_next!(actor::IgnoreActor{L}, data::L) where {L}
    if actor.skipped_count < actor.count
        actor.skipped_count += 1
    else
        next!(actor.actor, data)
    end
end

function on_error!(actor::IgnoreActor, err)
    error!(actor.actor, err)
end

function on_complete!(actor::IgnoreActor)
    complete!(actor.actor)
end

Base.show(io::IO, ::IgnoreOperator) = print(io, "IgnoreOperator()")
Base.show(io::IO, ::IgnoreProxy) = print(io, "IgnoreProxy()")
Base.show(io::IO, ::IgnoreActor{L}) where {L} = print(io, "IgnoreActor($L)")
