export max
export MaxOperator, on_call!
export MaxProxy, actor_proxy!
export MaxActor, on_next!, on_error!, on_complete!

import Base: max

max(::Type{T}, from = nothing) where T = MaxOperator{T}(from)

struct MaxOperator{T} <: Operator{T, T}
    from :: Union{Nothing, T}
end

function on_call!(operator::MaxOperator{T}, source::S) where { S <: Subscribable{T} } where T
    return ProxyObservable{T}(source, MaxProxy{T}(operator.from))
end

struct MaxProxy{T} <: ActorProxy
    from :: Union{Nothing, T}
end

actor_proxy!(proxy::MaxProxy{T}, actor::A) where { A <: AbstractActor{T} } where T = MaxActor{T}(proxy.from, actor)

mutable struct MaxActor{T} <: Actor{T}
    current :: Union{Nothing, T}
    actor
end

function on_next!(actor::MaxActor{T}, data::T) where T
    if actor.current == nothing
        actor.current = data
    else
        actor.current = data > actor.current ? data : actor.current
    end

    next!(actor.actor, actor.current)
end

on_error!(actor::MaxActor{T}, error) where T = error!(actor.actor, error)
on_complete!(actor::MaxActor{T})     where T = complete!(actor.actor)
