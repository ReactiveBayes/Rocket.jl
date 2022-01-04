export safe

import Base: show

"""
    safe()

Creates a `SafeOperator`, which wraps `on_subscribe!` as well as `on_next!`, `on_error!`, and `complete!` callbacks into try-catch block.

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream

See also: [`Operator`](@ref)
"""
safe() = SafeOperator()

struct SafeOperator <: Operator end

operator_eltype(::SafeOperator, ::Type{L}) where L = L

struct SafeSubscribable{L, S} <: Subscribable{L}
    source :: S
end

mutable struct SafeActor{A}
    actor        :: A
    isfailed     :: Bool
    subscription :: Subscription
end

function on_call!(::Type{L}, ::Type{L}, operator::SafeOperator, source::S) where { L, S }
    return SafeSubscribable{L, S}(source)
end

function on_subscribe!(source::SafeSubscribable, actor::A) where A
    safeactor = SafeActor{A}(actor, false, noopSubscription)
    try
        subscription = subscribe!(source.source, safeactor)
        setsubscription!(safeactor, subscription)
        return subscription
    catch exception
        dispose!(safeactor)
        on_error!(safeactor.actor, exception)
        return noopSubscription
    end
end

isfailed(actor::SafeActor)   = actor.isfailed
setfailed!(actor::SafeActor) = actor.isfailed = true

getsubscription(actor::SafeActor)         = actor.subscription
setsubscription!(actor::SafeActor, value) = actor.subscription = value

function on_next!(actor::SafeActor, data) where L
    if !isfailed(actor)
        try
            on_next!(actor.actor, data)
        catch exception
            dispose!(actor)
            on_error!(actor.actor, exception)
        end
    end
end

function on_error!(actor::SafeActor, err)
    if !isfailed(actor)
        try
            on_error!(actor.actor, err)
        catch exception
            dispose!(actor)
            on_error!(actor.actor, exception)
        end
    end
end

function on_complete!(actor::SafeActor)
    if !isfailed(actor)
        try
            on_complete!(actor.actor)
        catch exception
            dispose!(actor)
            on_error!(actor.actor, exception)
        end
    end
end

function dispose!(actor::SafeActor)
    setfailed!(actor)
    unsubscribe!(getsubscription(actor))
end

Base.show(io::IO, ::SafeOperator)                = print(io, "SafeOperator()")
Base.show(io::IO, ::SafeSubscribable{L}) where L = print(io, "SafeSubscribable($L)")
Base.show(io::IO, ::SafeActor)                   = print(io, "SafeActor()")
