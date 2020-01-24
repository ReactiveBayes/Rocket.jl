export delay
export DelayOperator, on_call!
export DelayProxy, actor_proxy!
export DelayActor, on_next!, on_error!, on_complete!, is_exhausted

"""
    delay(delay::Int)

Creates a delay operators, which delays the emission of items from the source Observable
by a given timeout.

# Arguments:
- `delay::Int`: the delay duration in milliseconds (a number) until which the emission of the source items is delayed.

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref)
"""
delay(delay::Int) = DelayOperator(delay)

struct DelayOperator <: InferableOperator
    delay :: Int
end

function on_call!(::Type{L}, ::Type{L}, operator::DelayOperator, source) where L
    return proxy(L, source, DelayProxy{L}(operator.delay))
end

operator_right(operator::DelayOperator, ::Type{L}) where L = L

struct DelayProxy{L} <: ActorSourceProxy
    delay :: Int
end

actor_proxy!(proxy::DelayProxy{L}, actor::A) where L where A = DelayActor{L, A}(false, proxy.delay, actor)
source_proxy!(proxy::DelayProxy{L}, source)  where L         = DelayObservable{L}(source)

mutable struct DelayActor{L, A} <: Actor{L}
    is_cancelled :: Bool
    delay        :: Int
    actor        :: A
end

is_exhausted(actor::DelayActor) = is_exhausted(actor.actor)

function on_next!(actor::DelayActor{L}, data::L) where L
    @async begin
        sleep(actor.delay / MILLISECONDS_IN_SECOND)
        if !actor.is_cancelled
            next!(actor.actor, data)
        end
    end
end

function on_error!(actor::DelayActor, err)
    @async begin
        sleep(actor.delay / MILLISECONDS_IN_SECOND)
        if !actor.is_cancelled
            error!(actor.actor, err)
        end
    end
end

function on_complete!(actor::DelayActor)
    @async begin
        sleep(actor.delay / MILLISECONDS_IN_SECOND)
        if !actor.is_cancelled
            complete!(actor.actor)
        end
    end
end

struct DelayObservable{L} <: Subscribable{L}
    source
end

function on_subscribe!(observable::DelayObservable, actor::DelayActor)
    return DelaySubscription(actor, subscribe!(observable.source, actor))
end

struct DelaySubscription <: Teardown
    actor
    subscription
end

as_teardown(::Type{<:DelaySubscription}) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::DelaySubscription)
    subscription.actor.is_cancelled = true
    unsubscribe!(subscription.subscription)
    return nothing
end
