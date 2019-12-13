export filter
export FilterOperator, on_call!
export FilterProxy, actor_proxy!
export FilterActor, on_next!, on_error!, on_complete!
export @CreateFilterOperator

import Base: filter

filter(::Type{T}, filterFn::Function) where T = FilterOperator{T}(filterFn)

struct FilterOperator{T} <: Operator{T, T}
    filterFn::Function
end

function on_call!(operator::FilterOperator{T}, source::S) where { S <: Subscribable{T} } where T
    return ProxyObservable{T}(source, FilterProxy{T}(operator.filterFn))
end

struct FilterProxy{T} <: ActorProxy
    filterFn::Function
end

actor_proxy!(proxy::FilterProxy{T}, actor::A) where { A <: AbstractActor{T} } where T = FilterActor{T, A}(proxy.filterFn, actor)


struct FilterActor{T, A <: AbstractActor{T} } <: Actor{T}
    filterFn :: Function
    actor    :: A
end

function on_next!(f::FilterActor{T, A}, data::T) where { A <: AbstractActor{T} } where T
    if (Base.invokelatest(f.filterFn, data))
        next!(f.actor, data)
    end
end

on_error!(f::FilterActor, error) = error!(f.actor, error)
on_complete!(f::FilterActor)     = complete!(f.actor)


macro CreateFilterOperator(name, filterFn)
    operatorName = Symbol(name, "FilterOperator")
    proxyName    = Symbol(name, "FilterProxy")
    actorName    = Symbol(name, "FilterActor")

    operatorDefinition = quote
        struct $operatorName{T} <: Rx.Operator{T, T} end

        function Rx.on_call!(operator::($operatorName){T}, source::S) where { S <: Rx.Subscribable{T} } where T
            return Rx.ProxyObservable{T}(source, ($proxyName){T}())
        end
    end

    proxyDefinition = quote
        struct $proxyName{T} <: Rx.ActorProxy end

        Rx.actor_proxy!(proxy::($proxyName){T}, actor::A) where { A <: Rx.AbstractActor{T} } where T = ($actorName){T, A}(actor)
    end

    actorDefintion = quote
        struct $actorName{T, A <: Rx.AbstractActor{T} } <: Rx.Actor{T}
            actor::A
        end

        Rx.on_next!(a::($actorName){T, A}, data::T) where A <: Rx.AbstractActor{T} where T = begin
            __inlined_lambda = $filterFn
            if (__inlined_lambda(data))
                Rx.next!(a.actor, data)
            end
        end

        Rx.on_error!(a::($actorName), error) = Rx.error!(a.actor, error)
        Rx.on_complete!(a::($actorName))     = Rx.complete!(a.actor)
    end

    generated = quote
        $operatorDefinition
        $proxyDefinition
        $actorDefintion
    end

    return esc(generated)
end
