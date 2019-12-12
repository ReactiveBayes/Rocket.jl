export take
export TakeOperator, on_call!
export TakeProxy, source_proxy!
export TakeInnerActor, on_next!, on_error!, on_complete!
export TakeSource, on_subscribe!

take(::Type{T}, max_count::Int) where T = TakeOperator{T}(max_count)

struct TakeOperator{T} <: Operator{T, T}
    max_count :: Int
end

function on_call!(operator::TakeOperator{T}, source::S) where { S <: Subscribable{T} } where T
    return ProxyObservable{T}(source, TakeProxy{T}(operator.max_count))
end

struct TakeProxy{T} <: SourceProxy
    max_count :: Int
end

source_proxy!(proxy::TakeProxy{T}, source::S)  where { S <: Subscribable{T} } where T = TakeSource{T}(proxy.max_count, source)

mutable struct TakeInnerActor{T} <: Actor{T}
    is_completed :: Bool
    max_count    :: Int
    current      :: Int
    subject      :: Subject{T}
    subscription

    TakeInnerActor{T}(max_count::Int, subject::Subject{T}) where T = begin
        actor = new()

        actor.is_completed = false
        actor.max_count    = max_count
        actor.current      = 0
        actor.subject      = subject

        return actor
    end
end

function on_next!(actor::TakeInnerActor{T}, data::T) where T
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

function on_error!(actor::TakeInnerActor{T}, error) where T
    if !actor.is_completed
        error!(actor.subject, error)
        if isdefined(actor, :subscription)
            unsubscribe!(actor.subscription)
        end
    end
end

function on_complete!(actor::TakeInnerActor{T}) where T
    if !actor.is_completed
        actor.is_completed = true
        complete!(actor.subject)
        if isdefined(actor, :subscription)
            unsubscribe!(actor.subscription)
        end
    end
end

struct TakeSource{T} <: Subscribable{T}
    max_count :: Int
    subject   :: Subject{T}
    source

    TakeSource{T}(max_count::Int, source) where T = new(max_count, Subject{T}(), source)
end

function on_subscribe!(observable::TakeSource{T}, actor::A) where { A <: AbstractActor{T} } where T
    inner_actor  = TakeInnerActor{T}(observable.max_count, observable.subject)
    subscription = subscribe!(observable.source, inner_actor)

    inner_actor.subscription = subscription

    return subscribe!(observable.subject, actor)
end
