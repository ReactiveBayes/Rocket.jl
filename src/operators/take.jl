export take

import Base: show

"""
    take(max_count::Int)

Creates a take operator, which returns an Observable
that emits only the first `max_count` values emitted by the source Observable.

# Arguments
- `max_count::Int`: the maximum number of next values to emit.

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
take(max_count::Int) = TakeOperator(max_count)

struct TakeOperator <: InferableOperator
    max_count :: Int
end

function on_call!(::Type{L}, ::Type{L}, operator::TakeOperator, source) where L
    return proxy(L, source, TakeProxy{L}(operator.max_count))
end

operator_right(operator::TakeOperator, ::Type{L}) where L = L

struct TakeProxy{L} <: SourceProxy
    max_count :: Int
end

source_proxy!(proxy::TakeProxy{L}, source::S) where { L, S } = TakeSource{L, S}(proxy.max_count, source)

mutable struct TakeCountingActor{L, A} <: Actor{L}
    is_completed :: Bool
    max_count    :: Int
    current      :: Int
    actor        :: A
    subscription :: Union{Any, Nothing}

    TakeCountingActor{L, A}(max_count::Int, actor::A) where { L, A } = begin
        take_actor = new()

        take_actor.is_completed = false
        take_actor.max_count    = max_count
        take_actor.current      = 0
        take_actor.actor        = actor
        take_actor.subscription = nothing

        return take_actor
    end
end

is_exhausted(actor::TakeCountingActor) = actor.is_completed || is_exhausted(actor.actor)

function on_next!(actor::TakeCountingActor{L}, data::L) where L
    if !actor.is_completed
        if actor.current < actor.max_count
            actor.current += 1
            next!(actor.actor, data)
            if actor.current == actor.max_count
                complete!(actor)
            end
        end
    end
end

function on_error!(actor::TakeCountingActor, err)
    if !actor.is_completed
        error!(actor.actor, err)
        if actor.subscription !== nothing
            unsubscribe!(actor.subscription)
        end
    end
end

function on_complete!(actor::TakeCountingActor)
    if !actor.is_completed
        actor.is_completed = true
        complete!(actor.actor)
        if actor.subscription !== nothing
            unsubscribe!(actor.subscription)
        end
    end
end

struct TakeSource{L, S} <: Subscribable{L}
    max_count :: Int
    source    :: S
end

function on_subscribe!(observable::TakeSource{L}, actor::A) where { L, A }
    counting_actor = TakeCountingActor{L, A}(observable.max_count, actor)
    subscription   = subscribe!(observable.source, counting_actor)

    counting_actor.subscription = subscription

    return subscription
end

Base.show(io::IO, ::TakeOperator)                 = print(io, "TakeOperator()")
Base.show(io::IO, ::TakeProxy{L})         where L = print(io, "TakeProxy($L)")
Base.show(io::IO, ::TakeCountingActor{L}) where L = print(io, "TakeCountingActor($L)")
Base.show(io::IO, ::TakeSource{L})        where L = print(io, "TakeSource($L)")
