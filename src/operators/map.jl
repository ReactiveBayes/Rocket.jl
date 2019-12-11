export map
export MapOperator
export MapProxy, proxy!, on_call!
export MapActor, on_next!, on_error!, on_complete!

import Base: map

map(::Type{T}, ::Type{R}, mappingFn::Function) where T where R = MapOperator{T, R}(mappingFn)

struct MapOperator{T, R} <: Operator{T, R}
    mappingFn::Function
end

struct MapProxy{T, R} <: Proxy
    mappingFn::Function
end

proxy!(proxy::MapProxy{T, R}, actor::A) where { A <: AbstractActor{R} } where T where R = MapActor{T, R}(proxy.mappingFn, actor)

function on_call!(operator::MapOperator{T, R}, source::S) where { S <: Subscribable{T} } where T where R
    return ProxyObservable{R}(source, MapProxy{T, R}(operator.mappingFn))
end

struct MapActor{T, R} <: Actor{T}
    mappingFn  :: Function
    actor
end

on_next!(m::MapActor{T, R},  data::T) where T where R = next!(m.actor, m.mappingFn(data))
on_error!(m::MapActor{T, R}, error)   where T where R = error!(m.actor, error)
on_complete!(m::MapActor{T, R})       where T where R = complete!(m.actor)
