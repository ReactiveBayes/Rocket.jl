export skip_complete

import Base: show

"""
    skip_complete()

Creates a `skip_complete` operator, which filters out `complete` event by the source Observable by emitting only
`next` and `error` messages.

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream

# Examples
```jldoctest
using Rocket

source = from([ 1, 2, 3 ])
subscribe!(source |> skip_complete(), logger())
;

# output
[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Data: 3

```

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref), [`skip_error`](@ref), [`skip_next`](@ref), [`logger`](@ref)
"""
skip_complete() = SkipCompleteOperator()

struct SkipCompleteOperator <: InferableOperator end

function on_call!(::Type{L}, ::Type{L}, operator::SkipCompleteOperator, source) where {L}
    return proxy(L, source, SkipCompleteProxy())
end

operator_right(operator::SkipCompleteOperator, ::Type{L}) where {L} = L

struct SkipCompleteProxy <: ActorProxy end

actor_proxy!(::Type{L}, proxy::SkipCompleteProxy, actor::A) where {L,A} =
    SkipCompleteActor{L,A}(actor)

struct SkipCompleteActor{L,A} <: Actor{L}
    actor::A
end

on_next!(actor::SkipCompleteActor{L}, data::L) where {L} = next!(actor.actor, data)
on_error!(actor::SkipCompleteActor, err) = error!(actor.actor, err)
on_complete!(actor::SkipCompleteActor) = begin end

Base.show(io::IO, ::SkipCompleteOperator) = print(io, "SkipCompleteOperator()")
Base.show(io::IO, ::SkipCompleteProxy) = print(io, "SkipCompleteProxy()")
Base.show(io::IO, ::SkipCompleteActor{L}) where {L} = print(io, "SkipCompleteActor($L)")
