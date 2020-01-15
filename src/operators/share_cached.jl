export ShareCachedOperator, on_call!, operator_right
export SharedCachedProxy, source_proxy!
export ShareCachedObservable, on_subscribe!
export ShareCachedActor, on_next!, on_error!, on_complete!, is_exhausted
export share_cached

import DataStructures: CircularBuffer

share_cached(count::Int) = ShareCachedOperator(count)

struct ShareCachedOperator <: InferableOperator
    count :: Int
end

function on_call!(::Type{L}, ::Type{L}, operator::ShareCachedOperator, source) where L
    return ProxyObservable{L}(source, SharedCachedProxy{L}(operator.count))
end

operator_right(operator::ShareCachedOperator, ::Type{L}) where L = L

struct SharedCachedProxy{L} <: SourceProxy
    count :: Int
end

source_proxy!(proxy::SharedCachedProxy{L}, source) where L = ShareCachedObservable{L}(proxy.count, source)

struct ShareCachedActor{L} <: Actor{L}
    index :: Int
    actor
    share_cached_observable
end

is_exhausted(actor::ShareCachedActor) = is_exhausted(actor.actor)

function on_next!(actor::ShareCachedActor{L}, data::L) where L
    next!(actor.actor, data)
    if actor.index == 0 && !actor.share_cached_observable.is_source_completed
        push!(actor.share_cached_observable.cb, data)
    end
end

function on_error!(actor::ShareCachedActor, err)
    error!(actor.actor, err)
end

function on_complete!(actor::ShareCachedActor)
    complete!(actor.actor)
    actor.share_cached_observable.is_source_completed = true
end

mutable struct ShareCachedObservable{L} <: Subscribable{L}
    observers_count :: Int
    cb :: CircularBuffer{L}

    is_source_completed :: Bool
    source

    ShareCachedObservable{L}(count::Int, source) where L = new(0, CircularBuffer{L}(count), false, source)
end

mutable struct ShareCachedSubscription <: Teardown
    is_unsubscribed :: Bool
    source_subscription
    share_cached_observable
end

function on_subscribe!(observable::ShareCachedObservable{L}, actor) where L
    for v in observable.cb
        next!(actor, v)
    end

    if !is_exhausted(actor)
        share_cached_actor = ShareCachedActor{L}(observable.observers_count, actor, observable)
        observable.observers_count += 1

        source_subscription = subscribe!(observable.source, share_cached_actor)
        return ShareCachedSubscription(false, source_subscription, observable)
    else
        return VoidTeardown()
    end
end

as_teardown(::Type{<:ShareCachedSubscription}) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::ShareCachedSubscription)
    if !subscription.is_unsubscribed
        subscription.is_unsubscribed = true
        subscription.share_cached_observable.observers_count -= 1
        return unsubscribe!(subscription.source_subscription)
    else
        return nothing
    end
end
