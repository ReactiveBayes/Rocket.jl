export tap
export TapOperator, on_call!
export TapProxy, actor_proxy!
export TapActor, on_next!, on_error!, on_complete!

tap(::Type{T}, tapFn::Function) where T = TapOperator{T}(tapFn)

struct TapOperator{T} <: Operator{T, T}
    tapFn :: Function
end

function on_call!(operator::TapOperator{T}, source::S) where { S <: Subscribable{T} } where T
    return ProxyObservable{T}(source, TapProxy{T}(operator.tapFn))
end

struct TapProxy{T} <: ActorProxy
    tapFn :: Function
end

actor_proxy!(proxy::TapProxy{T}, actor::A) where { A <: AbstractActor{T} } where T = TapActor{T}(proxy.tapFn, actor)

struct TapActor{T} <: Actor{T}
    tapFn :: Function
    actor
end

function on_next!(t::TapActor{T}, data::T) where T
    Base.invokelatest(t.tapFn, data)
    next!(t.actor, data)
end

on_error!(t::TapActor{T}, error) where T = error!(t.actor, error)
on_complete!(t::TapActor{T})     where T = complete!(t.actor)
