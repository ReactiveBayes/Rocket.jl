export last
export LastOperator, on_call!
export LastProxy, actor_proxy!
export LastActor, on_next!, on_error!, on_complete!

last(::Type{T}, default = nothing) where T = LastOperator{T}(default)

struct LastOperator{T} <: Operator{T, T}
    default :: Union{Nothing, T}
end

function on_call!(operator::LastOperator{T}, source::S) where { S <: Subscribable{T} } where T
    return ProxyObservable{T}(source, LastProxy{T}(operator.default))
end

struct LastProxy{T} <: ActorProxy
    default :: Union{Nothing, T}
end

function actor_proxy!(proxy::LastProxy{T}, actor::A) where { A <: AbstractActor{T} } where T
    return LastActor{T}(proxy.default != nothing ? copy(proxy.default) : nothing, actor)
end

mutable struct LastActor{T} <: Actor{T}
    last   :: Union{Nothing, T}
    actor
end

function on_next!(actor::LastActor{T}, data::T) where T
    actor.last = data
end

on_error!(actor::LastActor{T}, error) where T = error!(actor.actor, error)

function on_complete!(actor::LastActor{T}) where T
    if actor.last != nothing
        next!(actor.actor, actor.last)
    end
    complete!(actor.actor)
end
