export delay
export DelayOperator, on_call!
export DelayProxy, actor_proxy!
export DelayActor, on_next!, on_error!, on_complete!

"""
    delay(::Type{T}, delay::Int) where T

Creates a delay operators, which delays the emission of items from the source Observable
by a given timeout.

# Arguments:
- `delay::Int`: the delay duration in milliseconds (a number) until which the emission of the source items is delayed.
"""
delay(::Type{T}, delay::Int) where T = DelayOperator{T}(delay)

struct DelayOperator{T} <: Operator{T, T}
    delay :: Int
end

function on_call!(operator::DelayOperator{T}, source::S) where { S <: Subscribable{T} } where T
    return ProxyObservable{T}(source, DelayProxy{T}(operator.delay))
end

struct DelayProxy{T} <: ActorSourceProxy
    delay :: Int
end

actor_proxy!(proxy::DelayProxy{T}, actor::A) where { A <: AbstractActor{T} } where T  = DelayActor{T, A}(false, proxy.delay, actor)
source_proxy!(proxy::DelayProxy{T}, source::S) where { S <: Subscribable{T} } where T = DelayObservable{T, S}(source)

mutable struct DelayActor{T, A <: AbstractActor{T} } <: Actor{T}
    is_cancelled :: Bool
    delay        :: Int
    actor        :: A
end

function on_next!(actor::DelayActor{T, A}, data::T) where { A <: AbstractActor{T} } where T
    @async begin
        sleep(actor.delay / MILLISECONDS_IN_SECOND)
        if !actor.is_cancelled
            next!(actor.actor, data)
        end
    end
end

function on_error!(actor::DelayActor{T, A}, err) where { A <: AbstractActor{T} } where T
    @async begin
        sleep(actor.delay / MILLISECONDS_IN_SECOND)
        if !actor.is_cancelled
            error!(actor.actor, err)
        end
    end
end

function on_complete!(actor::DelayActor{T, A}) where { A <: AbstractActor{T} } where T
    @async begin
        sleep(actor.delay / MILLISECONDS_IN_SECOND)
        if !actor.is_cancelled
            complete!(actor.actor)
        end
    end
end

struct DelayObservable{ T, S <: Subscribable{T} } <: Subscribable{T}
    source :: S
end

function on_subscribe!(observable::DelayObservable{T, S}, actor::DelayActor{T, A}) where { A <: AbstractActor{T} } where { S <: Subscribable{T} } where T
    return DelaySubscription(actor, subscribe!(observable.source, actor))
end

struct DelaySubscription{ T, A <: AbstractActor{T}, S <: Teardown } <: Teardown
    actor        :: DelayActor{T, A}
    subscription :: S
end

as_teardown(::Type{<:DelaySubscription}) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::DelaySubscription{T, A}) where { A <: AbstractActor{T} } where T
    subscription.actor.is_cancelled = true
    unsubscribe!(subscription.subscription)
    return nothing
end
