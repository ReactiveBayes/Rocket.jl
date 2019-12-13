export map
export MapOperator, on_call!
export MapProxy, actor_proxy!
export MapActor, on_next!, on_error!, on_complete!
export @CreateMapOperator

import Base: map

map(::Type{T}, ::Type{R}, mappingFn::Function) where T where R = MapOperator{T, R}(mappingFn)

struct MapOperator{T, R} <: Operator{T, R}
    mappingFn::Function
end

function on_call!(operator::MapOperator{T, R}, source::S) where { S <: Subscribable{T} } where T where R
    return ProxyObservable{R}(source, MapProxy{T, R}(operator.mappingFn))
end

struct MapProxy{T, R} <: ActorProxy
    mappingFn::Function
end

actor_proxy!(proxy::MapProxy{T, R}, actor::A) where { A <: AbstractActor{R} } where T where R = MapActor{T, R, A}(proxy.mappingFn, actor)

struct MapActor{T, R, A <: AbstractActor{R} } <: Actor{T}
    mappingFn  :: Function
    actor      :: A
end

on_next!(m::MapActor{T, R, A},  data::T) where { A <: AbstractActor{R} } where T where R = next!(m.actor, Base.invokelatest(m.mappingFn, data))
on_error!(m::MapActor, error)                                                            = error!(m.actor, error)
on_complete!(m::MapActor)                                                                = complete!(m.actor)


macro CreateMapOperator(name, mappingFn)
    operatorName   = Symbol(name, "MapOperator")
    proxyName      = Symbol(name, "MapProxy")
    actorName      = Symbol(name, "MapActor")

    operatorDefinition = quote
        struct $operatorName{T, R} <: Rx.Operator{T, R} end

        function Rx.on_call!(operator::($operatorName){T, R}, source::S) where { S <: Rx.Subscribable{T} } where T where R
            return Rx.ProxyObservable{R}(source, ($proxyName){T, R}())
        end
    end

    proxyDefinition = quote
        struct $proxyName{T, R} <: Rx.ActorProxy end

        Rx.actor_proxy!(proxy::($proxyName){T, R}, actor::A) where { A <: Rx.AbstractActor{R} } where T where R = ($actorName){T, R, A}(actor)
    end

    actorDefinition = quote
        struct $actorName{ T, R, A <: Rx.AbstractActor{R} } <: Rx.Actor{T}
            actor::A
        end

        Rx.on_next!(a::($actorName){T, R, A}, data::T) where { A <: Rx.AbstractActor{R} } where T where R = begin
            __inlined_lambda = $mappingFn
            Rx.next!(a.actor, __inlined_lambda(data))
        end

        Rx.on_error!(a::($actorName), error) = Rx.error!(a.actor, error)
        Rx.on_complete!(a::($actorName))     = Rx.complete!(a.actor)
    end

    generated = quote
        $operatorDefinition
        $proxyDefinition
        $actorDefinition
    end

    return esc(generated)
end
