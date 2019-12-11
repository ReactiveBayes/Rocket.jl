export filter
export FilterOperator, on_call!
export FilterProxy, proxy!
export FilterActor, on_next!, on_error!, on_complete!

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
    if (f.filterFn(data))
        next!(f.actor, data)
    end
end

on_error!(f::FilterActor{T}, error) where T = error!(f.actor, error)
on_complete!(f::FilterActor{T})     where T = complete!(f.actor)
