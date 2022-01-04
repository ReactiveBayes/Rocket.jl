export take

import Base: show

"""
    take(maxcount::Int)

Creates a take operator, which returns an Observable
that emits only the first `maxcount` values emitted by the source Observable.

# Arguments
- `maxcount::Int`: the maximum number of next values to emit.

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream

# Examples
```jldoctest
using Rocket

source = from([ i for i in 1:100 ])

subscribe!(source |> take(5), logger())
;

# output

[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Data: 3
[LogActor] Data: 4
[LogActor] Data: 5
[LogActor] Completed
```

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
take(maxcount::Int) = TakeOperator(maxcount)

struct TakeOperator <: Operator
    maxcount :: Int
end

operator_eltype(::TakeOperator, ::Type{L}) where L = L

struct TakeSubscribable{L, S} <: Subscribable{L}
    maxcount :: Int
    source   :: S
end

mutable struct TakeActor{A}
    maxcount     :: Int
    actor        :: A
    isdisposed   :: Bool
    count        :: Int
    subscription :: Subscription

    TakeActor{A}(maxcount::Int, actor::A) where A = new(maxcount, actor, false, 0, noopSubscription)
end

function on_call!(::Type{L}, ::Type{L}, operator::TakeOperator, source::S) where { L, S }
    return TakeSubscribable{L, S}(operator.maxcount, source)
end

function on_subscribe!(source::TakeSubscribable, actor::A) where A
    actor        = TakeActor{A}(source.maxcount, actor)
    subscription = subscribe!(source.source, actor)
    actor.subscription = subscription
    return subscription
end

function on_next!(actor::TakeActor, data)
    if !actor.isdisposed
        if actor.count < actor.maxcount
            on_next!(actor.actor, data)
            actor.count += 1
            if actor.count == actor.maxcount
                on_complete!(actor)
            end
        end
    end
end

function on_error!(actor::TakeActor, err)
    if !actor.isdisposed
        on_error!(actor.actor, err)
        dispose!(actor)
    end
end

function on_complete!(actor::TakeActor)
    if !actor.isdisposed
        on_complete!(actor.actor)
        dispose!(actor)
    end
end

function dispose!(actor::TakeActor)
    actor.isdisposed = true
    unsubscribe!(actor.subscription)
end

Base.show(io::IO, ::TakeOperator)                = print(io, "TakeOperator()")
Base.show(io::IO, ::TakeSubscribable{L}) where L = print(io, "TakeSubscribable($L)")
Base.show(io::IO, ::TakeActor)                   = print(io, "TakeActor()")
