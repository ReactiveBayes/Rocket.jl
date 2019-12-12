export sum
export SumOperator, on_call!
export SumProxy, actor_proxy!
export SumActor, on_next!, on_error!, on_complete!

import Base: sum

sum(::Type{T}, from = zero(T)) where T = SumOperator{T}(from)

struct SumOperator{T} <: Operator{T, T}
    from :: T
end

function on_call!(operator::SumOperator{T}, source::S) where { S <: Subscribable{T} } where T
    return ProxyObservable{T}(source, SumProxy{T}(operator.from))
end

struct SumProxy{T} <: ActorProxy
    from :: T
end

actor_proxy!(proxy::SumProxy{T}, actor::A) where { A <: AbstractActor{T} } where T = SumActor{T}(proxy.from, actor)

mutable struct SumActor{T} <: Actor{T}
    current :: T
    actor
end

function on_next!(actor::SumActor{T}, data::T) where T
    actor.current = actor.current + data
    next!(actor.actor, actor.current)
end

on_error!(actor::SumActor{T}, error) where T = error!(actor.actor, error)
on_complete!(actor::SumActor{T})     where T = complete!(actor.actor)
