export tap
export TapOperator, on_call!
export TapProxy, actor_proxy!
export TapActor, on_next!, on_error!, on_complete!
export @CreateTapOperator

tap(::Type{T}, tapFn::Function) where T = TapOperator{T}(tapFn)

struct TapOperator{T} <: Operator{T, T}
    tapFn :: Function
end

function on_call!(operator::TapOperator{T}, source::S) where { S <: Subscribable{T} } where T
    return ProxyObservable{T}(source, TapProxy{T}(operator.tapFn))
end

struct TapProxy{T} <: ActorProxy
    tapFn :: Function
end

actor_proxy!(proxy::TapProxy{T}, actor::A) where { A <: AbstractActor{T} } where T = TapActor{T, A}(proxy.tapFn, actor)

struct TapActor{T, A <: AbstractActor{T} } <: Actor{T}
    tapFn :: Function
    actor :: A
end

function on_next!(t::TapActor{T, A}, data::T) where { A <: AbstractActor{T} } where T
    Base.invokelatest(t.tapFn, data)
    next!(t.actor, data)
end

on_error!(t::TapActor{T}, error) where T = error!(t.actor, error)
on_complete!(t::TapActor{T})     where T = complete!(t.actor)

macro CreateTapOperator(name, tapFn)
    operatorName = Symbol(name, "TapOperator")
    proxyName    = Symbol(name, "TapProxy")
    actorName    = Symbol(name, "TapActor")

    operatorDefinition = quote
        struct $operatorName{T} <: Rx.Operator{T, T} end

        function Rx.on_call!(operator::($operatorName), source::S) where { S <: Rx.Subscribable{T} } where T
            return Rx.ProxyObservable{T}(source, ($proxyName){T}())
        end
    end

    proxyDefinition = quote
        struct $proxyName{T} <: Rx.ActorProxy end

        Rx.actor_proxy!(proxy::($proxyName){T}, actor::A) where { A <: Rx.AbstractActor{T} } where T = ($actorName){T, A}(actor)
    end

    actorDefinition = quote
        struct $actorName{T, A <: Rx.AbstractActor{T} } <: Rx.Actor{T}
            actor :: A
        end

        function Rx.on_next!(actor::($actorName){T, A}, data::T) where { A <: Rx.AbstractActor{T} } where T
            __inlined_lambda = $tapFn
            __inlined_lambda(data)
            Rx.next!(actor.actor, data)
        end

        Rx.on_error!(actor::($actorName), error) = Rx.next!(actor.actor, error)
        Rx.on_complete!(actor::($actorName))     = Rx.complete!(actor.actor)
    end

    generated = quote
        $operatorDefinition
        $proxyDefinition
        $actorDefinition
    end

    return esc(generated)
end
