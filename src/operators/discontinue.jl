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

struct DiscontinueOperator <: Operator end

function on_call!(::Type{L}, ::Type{L}, operator::DiscontinueOperator, source::S) where { L, S }
    return DiscontinueSubscribable{L, S}(source)
end

operator_eltype(::DiscontinueOperator, ::Type{L}) where L = L

struct DiscontinueSubscribable{L, S} <: Subscribable{L} 
    source :: S
end

function on_subscribe!(observable::DiscontinueSubscribable, actor::A) where { A }
    return subscribe!(observable.source, DiscontinueActor{A}(actor))
end

mutable struct DiscontinueActor{A}
    actor                :: A
    isnextpropagated     :: Bool
    iserrorpropagated    :: Bool
    iscompletepropagated :: Bool

    DiscontinueActor{A}(actor::A) where A = new(actor, false, false, false)
end

isnextpropagated(actor::DiscontinueActor)     = actor.isnextpropagated
iserrorpropagated(actor::DiscontinueActor)    = actor.iserrorpropagated
iscompletepropagated(actor::DiscontinueActor) = actor.iscompletepropagated

setnextpropagated!(actor::DiscontinueActor, value::Bool)     = actor.isnextpropagated = value
seterrorpropagated!(actor::DiscontinueActor, value::Bool)    = actor.iserrorpropagated = value
setcompletepropagated!(actor::DiscontinueActor, value::Bool) = actor.iscompletepropagated = value

function on_next!(actor::DiscontinueActor, data)
    if !isnextpropagated(actor)
        setnextpropagated!(actor, true)
        on_next!(actor.actor, data)
        setnextpropagated!(actor, false)
    end
end

function on_error!(actor::DiscontinueActor, err)
    if !iserrorpropagated(actor)
        seterrorpropagated!(actor, true)
        on_error!(actor.actor, err)
        seterrorpropagated!(actor, false)
    end
end

function on_complete!(actor::DiscontinueActor)
    if !iscompletepropagated(actor)
        setcompletepropagated!(actor, true)
        on_complete!(actor.actor)
        setcompletepropagated!(actor, false)
    end
end

Base.show(io::IO, ::DiscontinueOperator)                = print(io, "DiscontinueOperator()")
Base.show(io::IO, ::DiscontinueSubscribable{L}) where L = print(io, "DiscontinueSubscribable($L)")
Base.show(io::IO, ::DiscontinueActor)                   = print(io, "DiscontinueActor()")
