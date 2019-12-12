export map
export MapOperator
export MapProxy, proxy!, on_call!
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

struct MapProxy{T, R} <: Proxy
    mappingFn::Function
end

proxy!(proxy::MapProxy{T, R}, actor::A) where { A <: AbstractActor{R} } where T where R = MapActor{T, R}(proxy.mappingFn, actor)

struct MapActor{T, R} <: Actor{T}
    mappingFn  :: Function
    actor
end

on_next!(m::MapActor{T, R},  data::T) where T where R = next!(m.actor, Base.invokelatest(m.mappingFn, data))
on_error!(m::MapActor{T, R}, error)   where T where R = error!(m.actor, error)
on_complete!(m::MapActor{T, R})       where T where R = complete!(m.actor)

macro CreateMapOperator(name, T, R, mappingFn)
    operatorName   = Symbol(name, "MapOperator")
    proxyName      = Symbol(name, "MapProxy")
    actorName      = Symbol(name, "MapActor")

    operatorDefinition = quote
        struct $operatorName <: Operator{$T, $R} end

        function Rx.on_call!(operator::($operatorName), source::S) where { S <: Subscribable{$T} }
            return ProxyObservable{$R}(source, ($proxyName)())
        end
    end

    proxyDefinition = quote
        struct $proxyName <: Proxy end

        Rx.proxy!(proxy::($proxyName), actor::A) where { A <: Rx.AbstractActor{$R} } = ($actorName)(actor)
    end

    actorDefinition = quote
        struct $actorName{ A <: Rx.AbstractActor{$R} } <: Rx.Actor{$T}
            actor::A
        end

        Rx.on_next!(a::($actorName), data::($T)) = begin
            __inlined_lambda = $mappingFn
            next!(a.actor, __inlined_lambda(data))
        end

        Rx.on_error!(a::($actorName), error) = error!(a.actor, error)

        Rx.on_complete!(a::($actorName)) = complete!(a.actor)
    end

    generated = quote
        $operatorDefinition
        $proxyDefinition
        $actorDefinition
    end

    return esc(generated)
end
