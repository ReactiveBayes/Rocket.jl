export SwitchMapOperator, on_call!
export SwitchMapProxy, actor_proxy!
export SwitchMapInnerActor, SwitchMapActor, on_next!, on_error!, on_complete!, is_exhausted
export switchMap
export @CreateSwitchMapOperator

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

    current_subscription :: Union{Nothing, Teardown}

    SwitchMapActor{L, R}(mappingFn::Function, actor) where L where R = new(mappingFn, actor, nothing)
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
    actor.current_subscription = subscribe!(Base.invokelatest(actor.mappingFn, data), SwitchMapInnerActor{L, R}(actor))
end

on_error!(actor::SwitchMapActor, err) = error!(actor.actor, err)
on_complete!(actor::SwitchMapActor)   = complete!(actor.actor)

mutable struct SwitchMapSource{L} <: Subscribable{L}
    source
end

source_proxy!(proxy::SwitchMapProxy{L, R}, source) where L where R = SwitchMapSource{L}(source)

function on_subscribe!(source::SwitchMapSource{L}, actor) where L where R
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

# Macro helper

macro CreateSwitchMapOperator(name, mappingFn)
    operatorName   = Symbol(name, "SwitchMapOperator")
    proxyName      = Symbol(name, "SwitchMapProxy")
    actorName      = Symbol(name, "SwitchMapActor")
    innerActorName = Symbol(name, "SwitchMapInnerActor")

    operatorDefinition = quote
        struct $operatorName{R} <: Rx.RightTypedOperator{R} end

        function Rx.on_call!(::Type{L}, ::Type{R}, operator::($operatorName){R}, source) where L where R
            return Rx.ProxyObservable{R}(source, ($proxyName){L, R}())
        end
    end

    proxyDefinition = quote
        struct $proxyName{L, R} <: Rx.ActorSourceProxy end

        Rx.actor_proxy!(proxy::($proxyName){L, R}, actor)   where L where R = $(actorName){L, R}(actor)
        Rx.source_proxy!(proxy::($proxyName){L, R}, source) where L where R = Rx.SwitchMapSource{L}(source)
    end

    actorDefinition = quote
        mutable struct $actorName{L, R} <: Rx.Actor{L}
            actor
            current_subscription :: Union{Nothing, Teardown}

            ($actorName){L, R}(actor) where L where R = new(actor, nothing)
        end

        Rx.is_exhausted(actor::($actorName)) = Rx.is_exhausted(actor.actor)

        struct $innerActorName{L, R} <: Rx.Actor{R}
            switch_actor :: ($actorName){L, R}
        end

        Rx.is_exhausted(actor::$innerActorName) = Rx.is_exhausted(actor.switch_actor)

        Rx.on_next!(actor::($innerActorName){L, R}, data::R) where L where R = Rx.next!(actor.switch_actor.actor, data)
        Rx.on_error!(actor::($innerActorName),   err)                        = Rx.error!(actor.switch_actor, err)
        Rx.on_complete!(actor::($innerActorName))                            = begin end

        function Rx.on_next!(actor::($actorName){L, R}, data::L) where L where R
            if actor.current_subscription != nothing
                Rx.unsubscribe!(actor.current_subscription)
            end
            __inlined_lambda = $mappingFn
            actor.current_subscription = Rx.subscribe!(__inlined_lambda(data), ($innerActorName){L, R}(actor))
        end

        Rx.on_error!(actor::($actorName), err) = Rx.error!(actor.actor, err)
        Rx.on_complete!(actor::($actorName))   = Rx.complete!(actor.actor)
    end

    generated = quote
        $operatorDefinition
        $proxyDefinition
        $actorDefinition
    end

    return esc(generated)
end

@CreateSwitchMapOperator(__RxGeneratedIdentity, (d) -> d)

switchMap(::Type{T}) where T = __RxGeneratedIdentitySwitchMapOperator{T}()
