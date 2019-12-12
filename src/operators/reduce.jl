export reduce

import Base: reduce

reduce(::Type{T}, ::Type{R}, reduceFn::Function, initial::R) where T where R = ReduceOperator{T, R}(reduceFn, initial)

struct ReduceOperator{T, R} <: Operator{T, R}
    reduceFn :: Function
    initial  :: R
end

function on_call!(operator::ReduceOperator{T, R}, source::S) where { S <: Subscribable{T} } where T where R
    return ProxyObservable{R}(source, ReduceProxy{T, R}(operator.reduceFn, operator.initial))
end

struct ReduceProxy{T, R} <: ActorProxy
    reduceFn :: Function
    initial  :: R
end

actor_proxy!(proxy::ReduceProxy{T, R}, actor::A) where { A <: AbstractActor{R} } where T where R = ReduceActor{T, R}(proxy.reduceFn, copy(proxy.initial), actor)

mutable struct ReduceActor{T, R} <: Actor{T}
    reduceFn :: Function
    current  :: R
    actor
end

function on_next!(r::ReduceActor{T, R}, data::T) where T where R
    r.current = Base.invokelatest(r.reduceFn, data, r.current)
    next!(r.actor, r.current)
end

on_error!(r::ReduceActor{T, R}, error) where T where R = error!(r.actor, error)
on_complete!(r::ReduceActor{T, R})     where T where R = complete!(r.actor)
