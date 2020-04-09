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
    count :: Int
end

function on_call!(::Type{L}, ::Type{L}, operator::RerunOperator, source) where L
    return proxy(L, source, RerunProxy{L}(operator.count))
end

operator_right(operator::RerunOperator, ::Type{L}) where L = L

struct RerunProxy{L} <: ActorSourceProxy
    count :: Int
end

actor_proxy!(proxy::RerunProxy{L}, actor::A)   where { L, A } = RerunActor{L, A}(proxy.count, actor, nothing, nothing)
source_proxy!(proxy::RerunProxy{L}, source::S) where { L, S } = RerunSource{L, S}(source)

mutable struct RerunActor{L, A} <: Actor{L}
    count :: Int
    actor :: A

    current_source       :: Union{Nothing, Any}
    current_subscription :: Union{Nothing, Teardown}
end

is_exhausted(actor::RerunActor) = is_exhausted(actor.actor)

function on_next!(actor::RerunActor{L}, data::L) where L
    next!(actor.actor, data)
end

function on_error!(actor::RerunActor, err)
    if actor.current_subscription !== nothing
        unsubscribe!(actor.current_subscription)
    end

    if actor.count == 0
        error!(actor.actor, err)
    else
        actor.count -= 1
        actor.current_subscription = subscribe!(actor.current_source, actor)
    end
end

function on_complete!(actor::RerunActor)
    complete!(actor.actor)
end

struct RerunSource{L, S} <: Subscribable{L}
    source :: S
end

struct RerunSubscription <: Teardown
    rerun_actor
end

as_teardown(::Type{<:RerunSubscription}) = UnsubscribableTeardownLogic()

function on_subscribe!(source::RerunSource, actor::RerunActor)
    actor.current_source       = source.source
    actor.current_subscription = subscribe!(source.source, actor)

    return RerunSubscription(actor)
end

function on_unsubscribe!(subscription::RerunSubscription)
    current_subscription = subscription.rerun_actor.current_subscription

    subscription.rerun_actor.current_source       = nothing
    subscription.rerun_actor.current_subscription = nothing

    return unsubscribe!(current_subscription)
end

Base.show(io::IO, ::RerunOperator)             = print(io, "RerunOperator()")
Base.show(io::IO, ::RerunProxy{L})     where L = print(io, "RerunProxy($L)")
Base.show(io::IO, ::RerunActor{L})     where L = print(io, "RerunActor($L)")
Base.show(io::IO, ::RerunSource{L})    where L = print(io, "RerunSource($L)")
Base.show(io::IO, ::RerunSubscription)         = print(io, "RerunSubscription()")
