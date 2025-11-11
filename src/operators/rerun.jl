export rerun

import Base: show

"""
    rerun(count::Int = -1)

Returns an Observable that mirrors the source Observable with the exception of an error.
If the source Observable calls error, this method will resubscribe to the source Observable for a maximum of `count`
resubscriptions (given as a number parameter) rather than propagating the error call.

# Arguments:
- `count::Int`: Number of retry attempts before failing. Optional. Default is `-1`.

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream

# Examples
```jldoctest
using Rocket

source = from(1:3) |> safe() |> map(Int, (d) -> d > 1 ? error("Error") : d) |> rerun(3)

subscribe!(source, logger())
;

# output
[LogActor] Data: 1
[LogActor] Data: 1
[LogActor] Data: 1
[LogActor] Data: 1
[LogActor] Error: ErrorException("Error")
```

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`catch_error`](@ref), [`logger`](@ref), [`safe`](@ref)
"""
rerun(count::Int = -1) = RerunOperator(count)

struct RerunOperator <: InferableOperator
    count::Int
end

function on_call!(::Type{L}, ::Type{L}, operator::RerunOperator, source) where {L}
    return proxy(L, source, RerunProxy(operator.count))
end

operator_right(operator::RerunOperator, ::Type{L}) where {L} = L

struct RerunProxy <: SourceProxy
    count::Int
end

source_proxy!(::Type{L}, proxy::RerunProxy, source::S) where {L,S} =
    RerunSource{L,S}(proxy.count, source)

mutable struct RerunInnerActor{L,S,A} <: Actor{L}
    source::S
    actor::A
    count::Int
    subscription::Teardown
end

getsubscription(actor::RerunInnerActor) = actor.subscription
setsubscription!(actor::RerunInnerActor, value) = actor.subscription = value

getcount(actor::RerunInnerActor) = actor.count
setcount!(actor::RerunInnerActor, value) = actor.count = max(-1, value)

function on_next!(actor::RerunInnerActor{L}, data::L) where {L}
    next!(actor.actor, data)
end

function on_error!(actor::RerunInnerActor, err)
    unsubscribe!(getsubscription(actor))

    count = getcount(actor)
    if count === 0
        error!(actor.actor, err)
    else
        setcount!(actor, count - 1)
        setsubscription!(actor, subscribe!(actor.source, actor))
    end
end

function on_complete!(actor::RerunInnerActor)
    complete!(actor.actor)
end

@subscribable struct RerunSource{L,S} <: Subscribable{L}
    count::Int
    source::S
end

function on_subscribe!(source::RerunSource{L,S}, actor::A) where {L,S,A}
    inner = RerunInnerActor{L,S,A}(source.source, actor, source.count, voidTeardown)

    setsubscription!(inner, subscribe!(source.source, inner))

    return RerunSubscription(inner)
end

struct RerunSubscription{I} <: Teardown
    inner::I
end

as_teardown(::Type{<:RerunSubscription}) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::RerunSubscription)
    return unsubscribe!(getsubscription(subscription.inner))
end

Base.show(io::IO, ::RerunOperator) = print(io, "RerunOperator()")
Base.show(io::IO, ::RerunProxy) = print(io, "RerunProxy()")
Base.show(io::IO, ::RerunSource{L}) where {L} = print(io, "RerunSource($L)")
Base.show(io::IO, ::RerunSubscription) = print(io, "RerunSubscription()")
