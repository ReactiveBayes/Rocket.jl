export SwitchMapOperator, on_call!
export SwitchMapProxy, actor_proxy!
export SwitchMapInnerActor, SwitchMapActor, on_next!, on_error!, on_complete!, is_exhausted
export switchMap

switchMap(::Type{R}, mappingFn::Function) where R = SwitchMapOperator{R}(mappingFn)

struct SwitchMapOperator{R} <: RightTypedOperator{R}
    mappingFn :: Function
end

function on_call!(::Type{L}, ::Type{R}, operator::SwitchMapOperator{R}, source) where L where R
    return ProxyObservable{R}(source, SwitchMapProxy{L, R}(operator.mappingFn))
end

struct SwitchMapProxy{L, R} <: ActorSourceProxy
    mappingFn :: Function
end

actor_proxy!(proxy::SwitchMapProxy{L, R}, actor) where L where R = SwitchMapActor{L, R}(proxy.mappingFn, actor)

mutable struct SwitchMapActor{L, R} <: Actor{L}
    mappingFn :: Function
    actor

    current_source       :: Union{Nothing, Any}
    current_subscription :: Union{Nothing, Teardown}

    SwitchMapActor{L, R}(mappingFn::Function, actor) where L where R = new(mappingFn, actor, nothing, nothing)
end

is_exhausted(actor::SwitchMapActor) = is_exhausted(actor.actor)

struct SwitchMapInnerActor{L, R} <: Actor{R}
    switch_actor :: SwitchMapActor{L, R}
end

is_exhausted(actor::SwitchMapInnerActor) = is_exhausted(actor.switch_actor)

on_next!(actor::SwitchMapInnerActor{L, R}, data::R) where L where R = next!(actor.switch_actor.actor, data)
on_error!(actor::SwitchMapInnerActor,   err)                        = error!(actor.switch_actor, err)
on_complete!(actor::SwitchMapInnerActor)                            = begin end

function on_next!(actor::SwitchMapActor{L, R}, data::L) where L where R
    if actor.current_subscription != nothing
        unsubscribe!(actor.current_subscription)
    end

    switched = Base.invokelatest(actor.mappingFn, data)

    if actor.current_source != nothing
        actor.current_source.last = switched
    end

    actor.current_subscription = subscribe!(switched, SwitchMapInnerActor{L, R}(actor))
end

on_error!(actor::SwitchMapActor, err) = error!(actor.actor, err)
on_complete!(actor::SwitchMapActor)   = complete!(actor.actor)

# Source proxy #

mutable struct SwitchMapSource{L} <: Subscribable{L}
    source
    last   :: Union{Nothing, Any}

    SwitchMapSource{L}(source) where L = new(source, nothing)
end

source_proxy!(proxy::SwitchMapProxy{L, R}, source) where L where R = SwitchMapSource{L}(source)

function on_subscribe!(source::SwitchMapSource{L}, actor::SwitchMapActor{L, R}) where L where R
    if source.last != nothing
        actor.current_subscription = subscribe!(source.last, SwitchMapInnerActor{L, R}(actor))
    end
    actor.current_source = source
    return SwitchMapSubscription(subscribe!(source.source, actor), actor)
end

struct SwitchMapSubscription <: Teardown
    subscription
    actor
end

as_teardown(::Type{<:SwitchMapSubscription}) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::SwitchMapSubscription)
    unsubscribe!(subscription.subscription)
    if subscription.actor.current_subscription != nothing
        unsubscribe!(subscription.actor.current_subscription)
    end
end
