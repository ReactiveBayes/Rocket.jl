export switchMap
export @CreateSwitchMapOperator

# TODO: Work in progress
# TODO: Untested and undocumented

switchMap(::Type{R}, mappingFn::Function) where R = SwitchMapOperator{R}(mappingFn)

struct SwitchMapOperator{R} <: RightTypedOperator{R}
    mappingFn :: Function
end

function on_call!(::Type{L}, ::Type{R}, operator::SwitchMapOperator{R}, source) where L where R
    return proxy(R, source, SwitchMapProxy{L, R}(operator.mappingFn))
end

struct SwitchMapProxy{L, R} <: ActorSourceProxy
    mappingFn :: Function
end

actor_proxy!(proxy::SwitchMapProxy{L, R}, actor::A) where L where R where A = SwitchMapActor{L, R, A}(proxy.mappingFn, actor)

mutable struct SwitchMapActor{L, R, A} <: Actor{L}
    mappingFn :: Function
    actor     :: A

    current_subscription_completed :: Bool
    current_subscription :: Union{Nothing, Teardown}
    switch_completed     :: Bool
    switch_failed        :: Bool
    switch_last_error    :: Union{Nothing, Any}

    SwitchMapActor{L, R, A}(mappingFn::Function, actor::A) where L where R where A = new(mappingFn, actor, false, nothing, false, false, nothing)
end

is_exhausted(actor::SwitchMapActor) = actor.switch_completed || actor.switch_failed || is_exhausted(actor.actor)

struct SwitchMapInnerActor{L, R} <: Actor{R}
    switch_actor :: SwitchMapActor{L, R}
end

is_exhausted(actor::SwitchMapInnerActor) = is_exhausted(actor.switch_actor)

on_next!(actor::SwitchMapInnerActor{L, R}, data::R) where L where R = next!(actor.switch_actor.actor, data)
on_error!(actor::SwitchMapInnerActor,   err)                        = error!(actor.switch_actor, err)
on_complete!(actor::SwitchMapInnerActor)                            = begin
    if actor.switch_actor.switch_completed
        complete!(actor.switch_actor.actor)
    elseif actor.switch_actor.switch_failed
        error!(actor.switch_actor.actor, actor.switch_actor.switch_last_error)
    else
        actor.switch_actor.current_subscription_completed = true
    end
end

function on_next!(actor::SwitchMapActor{L, R}, data::L) where L where R
    if actor.current_subscription !== nothing
        unsubscribe!(actor.current_subscription)
    end

    actor.current_subscription           = nothing
    actor.current_subscription_completed = false

    subscription = subscribe!(Base.invokelatest(actor.mappingFn, data), SwitchMapInnerActor{L, R}(actor))

    if !actor.current_subscription_completed
        actor.current_subscription = subscription
    end
end

function on_error!(actor::SwitchMapActor, err)
    if !actor.switch_completed && !actor.switch_failed
        actor.switch_failed     = true
        actor.switch_last_error = err

        if actor.current_subscription == nothing
            error!(actor.actor, err)
        end
    end
end

function on_complete!(actor::SwitchMapActor)
    if !actor.switch_completed && !actor.switch_failed
        actor.switch_completed = true
        if actor.current_subscription == nothing
            complete!(actor.actor)
        end
    end
end

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
    if subscription.actor.current_subscription !== nothing
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
            return Rx.proxy(R, source, ($proxyName){L, R}())
        end
    end

    proxyDefinition = quote
        struct $proxyName{L, R} <: Rx.ActorSourceProxy end

        Rx.actor_proxy!(proxy::($proxyName){L, R}, actor::A) where L where R where A = $(actorName){L, R, A}(actor)
        Rx.source_proxy!(proxy::($proxyName){L, R}, source)  where L where R         = Rx.SwitchMapSource{L}(source)
    end

    actorDefinition = quote
        mutable struct $actorName{L, R, A} <: Rx.Actor{L}
            actor :: A
            current_subscription_completed :: Bool
            current_subscription :: Union{Nothing, Teardown}
            switch_completed     :: Bool
            switch_failed        :: Bool
            switch_last_error    :: Union{Nothing, Any}

            ($actorName){L, R, A}(actor::A) where L where R where A = new(actor, false, nothing, false, false, nothing)
        end

        Rx.is_exhausted(actor::($actorName)) = actor.switch_completed || actor.switch_failed || Rx.is_exhausted(actor.actor)

        struct $innerActorName{L, R} <: Rx.Actor{R}
            switch_actor :: ($actorName){L, R}
        end

        Rx.is_exhausted(actor::$innerActorName) = Rx.is_exhausted(actor.switch_actor)

        Rx.on_next!(actor::($innerActorName){L, R}, data::R) where L where R = Rx.next!(actor.switch_actor.actor, data)
        Rx.on_error!(actor::($innerActorName),   err)                        = Rx.error!(actor.switch_actor, err)
        Rx.on_complete!(actor::($innerActorName))                            = begin
            if actor.switch_actor.switch_completed
                complete!(actor.switch_actor.actor)
            elseif actor.switch_actor.switch_failed
                error!(actor.switch_actor.actor, actor.switch_actor.switch_last_error)
            else
                actor.switch_actor.current_subscription_completed = true
            end
        end

        function Rx.on_next!(actor::($actorName){L, R}, data::L) where L where R
            if actor.current_subscription !== nothing
                unsubscribe!(actor.current_subscription)
            end

            actor.current_subscription           = nothing
            actor.current_subscription_completed = false

            __inlined_lambda = $mappingFn
            subscription = subscribe!(__inlined_lambda(data), ($innerActorName){L, R}(actor))

            if !actor.current_subscription_completed
                actor.current_subscription = subscription
            end
        end

        Rx.on_error!(actor::($actorName), err) = begin
            if !actor.switch_completed && !actor.switch_failed
                actor.switch_failed     = true
                actor.switch_last_error = err

                if actor.current_subscription == nothing
                    Rx.error!(actor.actor, err)
                end
            end
        end

        Rx.on_complete!(actor::($actorName))   = begin
            if !actor.switch_completed && !actor.switch_failed
                actor.switch_completed = true
                if actor.current_subscription == nothing
                    Rx.complete!(actor.actor)
                end
            end
        end
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
