export safe

import Base: show

"""
    safe()

Creates a `SafeOperator`, which wraps `on_subscribe!` and each `next!`, `error!` and `complete!` callbacks into try-catch block.

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
safe() = SafeOperator()

struct SafeOperator <: InferableOperator end

function on_call!(::Type{L}, ::Type{L}, operator::SafeOperator, source) where L
    return proxy(L, source, SafeProxy())
end

operator_right(operator::SafeOperator, ::Type{L}) where L = L

struct SafeProxy <: ActorSourceProxy end

actor_proxy!(::Type{L}, proxy::SafeProxy, actor::A)   where { L, A } = SafeActor{L, A}(actor, SafeActorProps(false, voidTeardown))
source_proxy!(::Type{L}, proxy::SafeProxy, source::S) where { L, S } = SafeSource{L, S}(source)

mutable struct SafeActorProps
    isfailed     :: Bool
    subscription :: Teardown
end

struct SafeActor{L, A} <: Actor{L}
    actor :: A
    props :: SafeActorProps
end

isfailed(actor::SafeActor)   = actor.props.isfailed
setfailed!(actor::SafeActor) = actor.props.isfailed = true

getsubscription(actor::SafeActor)         = actor.props.subscription
setsubscription!(actor::SafeActor, value) = actor.props.subscription = value

function on_next!(actor::SafeActor{L}, data::L) where L
    if !isfailed(actor)
        try
            next!(actor.actor, data)
        catch exception
            dispose!(actor)
            error!(actor.actor, exception)
        end
    end
end

function on_error!(actor::SafeActor, err)
    if !isfailed(actor)
        try
            error!(actor.actor, err)
        catch exception
            dispose!(actor)
            error!(actor.actor, exception)
        end
    end
end

function on_complete!(actor::SafeActor)
    if !isfailed(actor)
        try
            complete!(actor.actor)
        catch exception
            dispose!(actor)
            error!(actor.actor, exception)
        end
    end
end

function dispose!(actor::SafeActor)
    setfailed!(actor)
    unsubscribe!(getsubscription(actor))
end

struct SafeSource{L, S} <: Subscribable{L}
    source :: S
end

function on_subscribe!(source::SafeSource, actor::SafeActor)
    try
        subscription = subscribe!(source.source, actor)
        setsubscription!(actor, subscription)
        return subscription
    catch exception
        dispose!(actor)
        error!(actor.actor, exception)
        return voidTeardown
    end
end

Base.show(io::IO, ::SafeOperator)          = print(io, "SafeOperator()")
Base.show(io::IO, ::SafeProxy)             = print(io, "SafeProxy()")
Base.show(io::IO, ::SafeActor{L})  where L = print(io, "SafeActor($L)")
Base.show(io::IO, ::SafeSource{L}) where L = print(io, "SafeSource($L)")
