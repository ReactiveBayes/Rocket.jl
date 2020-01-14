export take
export TakeOperator, on_call!
export TakeProxy, source_proxy!
export TakeInnerActor, on_next!, on_error!, on_complete!, is_exhausted
export TakeSource, on_subscribe!

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
using Rx

struct KeepActor{D} <: NextActor{D}
    values::Vector{D}

    KeepActor{D}() where D = new(Vector{D}())
end

Rx.on_next!(actor::KeepActor{D}, data::D) where D = push!(actor.values, data)

@sync begin
    source = from([ i for i in 1:100 ])
    actor  = KeepActor{Int}()
    subscription = subscribe!(source |> take(5), actor)
    println(actor.values)
end
;

# output

Int64[1, 2, 3, 4, 5]
```

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref)
"""
take(max_count::Int) = TakeOperator(max_count)

struct TakeOperator <: InferableOperator
    max_count :: Int
end

function on_call!(::Type{L}, ::Type{L}, operator::TakeOperator, source) where L
    return ProxyObservable{L}(source, TakeProxy{L}(operator.max_count))
end

operator_right(operator::TakeOperator, ::Type{L}) where L = L

struct TakeProxy{L} <: SourceProxy
    max_count :: Int
end

source_proxy!(proxy::TakeProxy{L}, source) where L = TakeSource{L}(proxy.max_count, source)

mutable struct TakeInnerActor{L} <: Actor{L}
    is_completed :: Bool
    max_count    :: Int
    current      :: Int
    actor
    subscription

    TakeInnerActor{L}(max_count::Int, actor) where L = begin
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

function on_subscribe!(observable::TakeSource{L}, actor) where L
    inner_actor  = TakeInnerActor{L}(observable.max_count, actor)

    subscription = subscribe!(observable.source, inner_actor)
    inner_actor.subscription = subscription

    return subscription
end
