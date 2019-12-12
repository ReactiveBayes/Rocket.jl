export filter
export FilterOperator, on_call!
export FilterProxy, proxy!
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

struct FilterProxy{T} <: Proxy
    filterFn::Function
end

proxy!(proxy::FilterProxy{T}, actor::A) where { A <: AbstractActor{T} } where T = FilterActor{T}(proxy.filterFn, actor)


struct FilterActor{T} <: Actor{T}
    filterFn :: Function
    actor
end

function on_next!(f::FilterActor{T}, data::T) where T
    if (Base.invokelatest(f.filterFn, data))
        next!(f.actor, data)
    end
end

on_error!(f::FilterActor{T}, error) where T = error!(f.actor, error)
on_complete!(f::FilterActor{T})     where T = complete!(f.actor)


macro CreateFilterOperator(name, T, filterFn)
    operatorName = Symbol(name, "FilterOperator")
    proxyName    = Symbol(name, "FilterProxy")
    actorName    = Symbol(name, "FilterActor")

    operatorDefinition = quote
        struct $operatorName <: Operator{$T, $T} end

        function Rx.on_call!(operator::($operatorName), source::S) where { S <: Subscribable{$T} }
            return ProxyObservable{$T}(source, ($proxyName)())
        end
    end

    proxyDefinition = quote
        struct $proxyName <: Proxy end

        Rx.proxy!(proxy::($proxyName), actor::A) where { A <: Rx.AbstractActor{$T} } = ($actorName)(actor)
    end

    actorDefintion = quote
        struct $actorName{ A <: Rx.AbstractActor{$T} } <: Rx.Actor{$T}
            actor::A
        end

        Rx.on_next!(a::($actorName), data::($T)) = begin
            __inlined_lambda = $filterFn
            if (__inlined_lambda(data))
                next!(a.actor, data)
            end
        end

        Rx.on_error!(a::($actorName), error) = error!(a.actor, error)

        Rx.on_complete!(a::($actorName)) = complete!(a.actor)
    end

    generated = quote
        $operatorDefinition
        $proxyDefinition
        $actorDefintion
    end

    return esc(generated)
end
