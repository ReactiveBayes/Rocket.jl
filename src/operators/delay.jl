export delay
export DelayOperator, on_call!
export DelayProxy, actor_proxy!
export DelayActor, on_next!, on_error!, on_complete!

"""
    delay(delay::Int)

Creates a delay operators, which delays the emission of items from the source Observable
by a given timeout.

# Arguments:
- `delay::Int`: the delay duration in milliseconds (a number) until which the emission of the source items is delayed.

# Producing

Stream of type <: Subscribable{L} where L refers to type of source stream

"""
delay(delay::Int) = DelayOperator(delay)

struct DelayOperator <: InferrableOperator
    delay :: Int
end

function on_call!(::Type{L}, ::Type{L}, operator::DelayOperator, source::S) where { S <: Subscribable{L} } where L
    return ProxyObservable{L}(source, DelayProxy{L}(operator.delay))
end

operator_right(operator::DelayOperator, ::Type{L}) where L = L

struct DelayProxy{L} <: ActorSourceProxy
    delay :: Int
end

actor_proxy!(proxy::DelayProxy{L}, actor::A) where { A <: AbstractActor{L} } where L  = DelayActor{L, A}(false, proxy.delay, actor)
source_proxy!(proxy::DelayProxy{L}, source::S) where { S <: Subscribable{L} } where L = DelayObservable{L, S}(source)

mutable struct DelayActor{L, A <: AbstractActor{L} } <: Actor{L}
    is_cancelled :: Bool
    delay        :: Int
    actor        :: A
end

function on_next!(actor::DelayActor{L, A}, data::L) where { A <: AbstractActor{L} } where L
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

struct DelayObservable{ L, S <: Subscribable{L} } <: Subscribable{L}
    source :: S
end

function on_subscribe!(observable::DelayObservable{L, S}, actor::DelayActor{L, A}) where { A <: AbstractActor{L} } where { S <: Subscribable{L} } where L
    return DelaySubscription(actor, subscribe!(observable.source, actor))
end

struct DelaySubscription{ L, A <: AbstractActor{L}, S <: Teardown } <: Teardown
    actor        :: DelayActor{L, A}
    subscription :: S
end

as_teardown(::Type{<:DelaySubscription}) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::DelaySubscription{L, A}) where { A <: AbstractActor{L} } where L
    subscription.actor.is_cancelled = true
    unsubscribe!(subscription.subscription)
    return nothing
end
