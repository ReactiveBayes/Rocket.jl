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
actor  = keep(Int)
subscription = subscribe!(source |> take(5), actor)
println(actor.values)
;

# output

[1, 2, 3, 4, 5]
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

source_proxy!(proxy::TakeProxy{L}, source) where L = TakeSource{L}(proxy.max_count, source)

mutable struct TakeInnerActor{L, A} <: Actor{L}
    is_completed :: Bool
    max_count    :: Int
    current      :: Int
    actor        :: A
    subscription

    TakeInnerActor{L, A}(max_count::Int, actor::A) where L where A = begin
        take_actor = new()

        take_actor.is_completed = false
        take_actor.max_count    = max_count
        take_actor.current      = 0
        take_actor.actor        = actor

        return take_actor
    end
end

is_exhausted(actor::TakeInnerActor) = actor.is_completed || is_exhausted(actor.actor)

function on_next!(actor::TakeInnerActor{L}, data::L) where L
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

function on_error!(actor::TakeInnerActor{L}, err) where L
    if !actor.is_completed
        error!(actor.actor, err)
        if isdefined(actor, :subscription)
            unsubscribe!(actor.subscription)
        end
    end
end

function on_complete!(actor::TakeInnerActor{L}) where L
    if !actor.is_completed
        actor.is_completed = true
        complete!(actor.actor)
        if isdefined(actor, :subscription)
            unsubscribe!(actor.subscription)
        end
    end
end

struct TakeSource{L} <: Subscribable{L}
    max_count :: Int
    source

    TakeSource{L}(max_count::Int, source) where L = new(max_count, source)
end

function on_subscribe!(observable::TakeSource{L}, actor::A) where L where A
    inner_actor  = TakeInnerActor{L, A}(observable.max_count, actor)

    subscription = subscribe!(observable.source, inner_actor)
    inner_actor.subscription = subscription

    return subscription
end

Base.show(io::IO, operator::TakeOperator)           = print(io, "TakeOperator()")
Base.show(io::IO, proxy::TakeProxy{L})      where L = print(io, "TakeProxy($L)")
Base.show(io::IO, actor::TakeInnerActor{L}) where L = print(io, "TakeInnerActor($L)")
Base.show(io::IO, source::TakeSource{L})    where L = print(io, "TakeSource($L)")
