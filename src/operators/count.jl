export count
export CountOperator, on_call!
export CountProxy, actor_proxy!
export CountActor, on_next!, on_error!, on_complete!

import Base: count

count(::Type{T}) where T = CountOperator{T}()

struct CountOperator{T} <: Operator{T, Int} end

function on_call!(operator::CountOperator{T}, source::S) where { S <: Subscribable{T} } where T
    return ProxyObservable{Int}(source, CountProxy{T}())
end

struct CountProxy{T} <: ActorProxy end

actor_proxy!(proxy::CountProxy{T}, actor::A) where { A <: AbstractActor{Int} } where T = CountActor{T}(actor)

mutable struct CountActor{T} <: Actor{T}
    current :: Int
    actor

    CountActor{T}(actor) where T = new(1, actor)
end

function on_next!(c::CountActor{T}, data::T) where T
    current = c.current
    c.current += 1
    next!(c.actor, current)
end

on_error!(c::CountActor{T}, error) where T = error!(c.actor, error)
on_complete!(c::CountActor{T})     where T = complete!(c.actor)
