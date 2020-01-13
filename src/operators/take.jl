export take
export TakeOperator, on_call!
export TakeProxy, source_proxy!
export TakeInnerActor, on_next!, on_error!, on_complete!
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
    subject      :: Subject{L}
    subscription

    TakeInnerActor{L}(max_count::Int, subject::Subject{L}) where L = begin
        actor = new()

        actor.is_completed = false
        actor.max_count    = max_count
        actor.current      = 0
        actor.subject      = subject

        return actor
    end
end

function on_next!(actor::TakeInnerActor{L}, data::L) where L
    if !actor.is_completed
        if actor.current < actor.max_count
            actor.current += 1
            next!(actor.subject, data)
            if actor.current == actor.max_count
                complete!(actor)
            end
        end
    end
end

function on_error!(actor::TakeInnerActor{L}, err) where L
    if !actor.is_completed
        error!(actor.subject, err)
        if isdefined(actor, :subscription)
            unsubscribe!(actor.subscription)
        end
    end
end

function on_complete!(actor::TakeInnerActor{L}) where L
    if !actor.is_completed
        actor.is_completed = true
        complete!(actor.subject)
        if isdefined(actor, :subscription)
            unsubscribe!(actor.subscription)
        end
    end
end

struct TakeSource{L} <: Subscribable{L}
    max_count :: Int
    subject   :: Subject{L}
    source

    TakeSource{L}(max_count::Int, source) where L = new(max_count, Subject{L}(), source)
end

function on_subscribe!(observable::TakeSource{L}, actor) where L
    inner_actor  = TakeInnerActor{L}(observable.max_count, observable.subject)

    subscription             = subscribe!(observable.subject, actor)
    inner_actor.subscription = subscribe!(observable.source, inner_actor)

    return subscription
end
