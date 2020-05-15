export discontinue

import Base: show

"""
    discontinue()

Creates an operator, which prevents an emitting of self-depending messages and breaks a possible infinite loop.
Does nothing if observable scheduled asynchronously.

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream

# Examples
```jldoctest
using Rocket

s = BehaviorSubject(0)

subscription1 = subscribe!(s, logger())
subscription2 = subscribe!(s |> map(Int, d -> d + 1) |> discontinue(), s)
;

# output

[LogActor] Data: 0
[LogActor] Data: 1
```

See also: [`AbstractOperator`](@ref), [`RightTypedOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
discontinue() = DiscontinueOperator()

struct DiscontinueOperator <: InferableOperator end

function on_call!(::Type{L}, ::Type{L}, operator::DiscontinueOperator, source) where L
    return proxy(L, source, DiscontinueProxy())
end

operator_right(::DiscontinueOperator, ::Type{L}) where L = L

struct DiscontinueProxy <: ActorProxy end

actor_proxy!(::Type{L}, proxy::DiscontinueProxy, actor::A) where { L, A } = DiscontinueActor{L, A}(actor)

mutable struct DiscontinueActorProps
    isnextpropagated     :: Bool
    iserrorpropagated    :: Bool
    iscompletepropagated :: Bool

    DiscontinueActorProps() = new(false, false, false)
end

struct DiscontinueActor{L, A} <: Actor{L}
    actor :: A
    props :: DiscontinueActorProps

    DiscontinueActor{L, A}(actor::A) where { L, A } = new(actor, DiscontinueActorProps())
end

isnextpropagated(actor::DiscontinueActor)     = actor.props.isnextpropagated
iserrorpropagated(actor::DiscontinueActor)    = actor.props.iserrorpropagated
iscompletepropagated(actor::DiscontinueActor) = actor.props.iscompletepropagated

setnextpropagated!(actor::DiscontinueActor, value::Bool)     = actor.props.isnextpropagated = value
seterrorpropagated!(actor::DiscontinueActor, value::Bool)    = actor.props.iserrorpropagated = value
setcompletepropagated!(actor::DiscontinueActor, value::Bool) = actor.props.iscompletepropagated = value

function on_next!(actor::DiscontinueActor{L}, data::L) where L
    if !isnextpropagated(actor)
        setnextpropagated!(actor, true)
        next!(actor.actor, data)
        setnextpropagated!(actor, false)
    end
end

function on_error!(actor::DiscontinueActor, err)
    if !iserrorpropagated(actor)
        seterrorpropagated!(actor, true)
        error!(actor.actor, err)
        seterrorpropagated!(actor, false)
    end
end

function on_complete!(actor::DiscontinueActor)
    if !iscompletepropagated(actor)
        setcompletepropagated!(actor, true)
        complete!(actor.actor)
        setcompletepropagated!(actor, false)
    end
end

Base.show(io::IO, ::DiscontinueOperator)         = print(io, "DiscontinueOperator()")
Base.show(io::IO, ::DiscontinueProxy)            = print(io, "DiscontinueProxy()")
Base.show(io::IO, ::DiscontinueActor{L}) where L = print(io, "DiscontinueActor($L)")
