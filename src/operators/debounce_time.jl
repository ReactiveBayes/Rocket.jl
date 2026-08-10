export debounce_time

import Base: show

"""
    debounce_time(due_time::Int)

Creates a `debounce_time` operator, which emits a value from the source Observable only after
a particular time span (`due_time`, in milliseconds) has passed without the source emitting
another value. Each new value restarts the quiet-period timer, so only the most recent value
is emitted once the source stays quiet for `due_time` milliseconds. If the source completes
while a value is still waiting out its quiet period, that pending value is emitted immediately
before the completion is forwarded.

# Arguments
- `due_time::Int`: the quiet-period duration in milliseconds

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to the type of the source stream

# Examples
```
using Rocket

# Values that arrive closer together than `due_time` collapse to the last one; the pending
# value is flushed when the source completes.
source = interval(10) |> take(5) |> debounce_time(100)

subscribe!(source, logger())
```

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
debounce_time(due_time::Int) = DebounceTimeOperator(due_time)

struct DebounceTimeOperator <: InferableOperator
    due_time::Int
end

function on_call!(::Type{L}, ::Type{L}, operator::DebounceTimeOperator, source) where {L}
    return proxy(L, source, DebounceTimeProxy(operator.due_time))
end

operator_right(operator::DebounceTimeOperator, ::Type{L}) where {L} = L

struct DebounceTimeProxy <: ActorSourceProxy
    due_time::Int
end

actor_proxy!(::Type{L}, proxy::DebounceTimeProxy, actor::A) where {L,A} =
    DebounceTimeActor{L,A}(proxy.due_time, actor)
source_proxy!(::Type{L}, proxy::DebounceTimeProxy, source::S) where {L,S} =
    DebounceTimeObservable{L,S}(source)

mutable struct DebounceTimeActor{L,A} <: Actor{L}
    due_time::Int
    actor::A
    last_value::Union{Nothing,L}
    has_pending::Bool
    is_completed::Bool
    is_cancelled::Bool
    timer::Union{Nothing,Timer}

    DebounceTimeActor{L,A}(due_time::Int, actor::A) where {L,A} =
        new(due_time, actor, nothing, false, false, false, nothing)
end

function __debounce_stop_timer!(actor::DebounceTimeActor)
    timer = actor.timer
    if timer !== nothing
        close(timer)
        actor.timer = nothing
    end
    return nothing
end

function __debounce_flush!(actor::DebounceTimeActor)
    if actor.is_cancelled || !actor.has_pending
        return nothing
    end
    actor.has_pending = false
    next!(actor.actor, actor.last_value)
    return nothing
end

function on_next!(actor::DebounceTimeActor{L}, data::L) where {L}
    actor.is_cancelled && return nothing
    actor.last_value = data
    actor.has_pending = true
    # Restart the quiet-period timer; the most recent value is emitted only once the
    # source has stayed quiet for `due_time` milliseconds.
    __debounce_stop_timer!(actor)
    actor.timer = Timer(actor.due_time / MILLISECONDS_IN_SECOND) do _
        __debounce_flush!(actor)
    end
    return nothing
end

function on_error!(actor::DebounceTimeActor, err)
    actor.is_cancelled && return nothing
    actor.is_cancelled = true
    __debounce_stop_timer!(actor)
    error!(actor.actor, err)
    return nothing
end

function on_complete!(actor::DebounceTimeActor)
    (actor.is_cancelled || actor.is_completed) && return nothing
    actor.is_completed = true
    __debounce_stop_timer!(actor)
    # Emit any value still waiting out its quiet period, then complete.
    __debounce_flush!(actor)
    complete!(actor.actor)
    return nothing
end

@subscribable struct DebounceTimeObservable{L,S} <: Subscribable{L}
    source::S
end

function on_subscribe!(observable::DebounceTimeObservable, actor::DebounceTimeActor)
    return DebounceTimeSubscription(actor, subscribe!(observable.source, actor))
end

struct DebounceTimeSubscription{A,S} <: Teardown
    actor::A
    subscription::S
end

as_teardown(::Type{<:DebounceTimeSubscription}) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::DebounceTimeSubscription)
    subscription.actor.is_cancelled = true
    __debounce_stop_timer!(subscription.actor)
    unsubscribe!(subscription.subscription)
    return nothing
end

Base.show(io::IO, ::DebounceTimeOperator) = print(io, "DebounceTimeOperator()")
Base.show(io::IO, ::DebounceTimeProxy) = print(io, "DebounceTimeProxy()")
Base.show(io::IO, ::DebounceTimeActor{L}) where {L} = print(io, "DebounceTimeActor($L)")
Base.show(io::IO, ::DebounceTimeObservable{L}) where {L} =
    print(io, "DebounceTimeObservable($L)")
Base.show(io::IO, ::DebounceTimeSubscription) = print(io, "DebounceTimeSubscription()")
