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
    return proxy(L, source, SafeProxy{L}())
end

operator_right(operator::SafeOperator, ::Type{L}) where L = L

struct SafeProxy{L} <: ActorSourceProxy end

actor_proxy!(proxy::SafeProxy{L}, actor::A)   where { L, A } = SafeActor{L, A}(actor, false, nothing)
source_proxy!(proxy::SafeProxy{L}, source::S) where { L, S } = SafeSource{L, S}(source)

mutable struct SafeActor{L, A} <: Actor{L}
    actor :: A

    is_failed            :: Bool
    current_subscription :: Union{Nothing, Teardown}
end

is_exhausted(actor::SafeActor) = actor.is_failed || is_exhausted(actor.actor)

function on_next!(actor::SafeActor{L}, data::L) where L
    if !actor.is_failed
        try
            next!(actor.actor, data)
        catch exception
            error!(actor.actor, exception)
            __safe_actor_dispose(actor)
        end
    end
end

function on_error!(actor::SafeActor, err)
    if !actor.is_failed
        try
            error!(actor.actor, err)
        catch exception
            error!(actor.actor, exception)
            __safe_actor_dispose(actor)
        end
    end
end

function on_complete!(actor::SafeActor)
    if !actor.is_failed
        try
            complete!(actor.actor)
        catch exception
            error!(actor.actor, exception)
            __safe_actor_dispose(actor)
        end
    end
end

function __safe_actor_dispose(actor::SafeActor)
    actor.is_failed = true
    if actor.current_subscription !== nothing
        unsubscribe!(actor.current_subscription)
        actor.current_subscription = nothing
    end
end

struct SafeSource{L, S} <: Subscribable{L}
    source :: S
end

function on_subscribe!(source::SafeSource, actor::SafeActor)
    try
        subscription = subscribe!(source.source, actor)
        actor.current_subscription = subscription
        return subscription
    catch exception
        error!(actor, exception)
        return VoidTeardown()
    end
end

Base.show(io::IO, ::SafeOperator)          = print(io, "SafeOperator()")
Base.show(io::IO, ::SafeProxy{L})  where L = print(io, "SafeProxy($L)")
Base.show(io::IO, ::SafeActor{L})  where L = print(io, "SafeActor($L)")
Base.show(io::IO, ::SafeSource{L}) where L = print(io, "SafeSource($L)")
