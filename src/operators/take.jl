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

struct TakeOperator <: InferableOperator
    maxcount :: Int
end

function on_call!(::Type{L}, ::Type{L}, operator::TakeOperator, source) where L
    return proxy(L, source, TakeProxy{L}(operator.maxcount))
end

operator_right(operator::TakeOperator, ::Type{L}) where L = L

struct TakeProxy{L} <: ActorSourceProxy
    maxcount :: Int
end

actor_proxy!(proxy::TakeProxy{L},  actor::A)  where { L, A } = TakeActor{L, A}(proxy.maxcount, actor)
source_proxy!(proxy::TakeProxy{L}, source::S) where { L, S } = TakeSource{L, S}(source)

mutable struct TakeActorProps
    isdisposed   :: Bool
    count        :: Int
    subscription :: Teardown

    TakeActorProps() = new(false, 0, voidTeardown)
end

struct TakeActor{L, A} <: Actor{L}
    maxcount :: Int
    actor    :: A
    props    :: TakeActorProps

    TakeActor{L, A}(maxcount::Int, actor::A) where { L, A } = new(maxcount, actor, TakeActorProps())
end

function on_next!(actor::TakeActor{L}, data::L) where L
    props = actor.props
    if !props.isdisposed
        if props.count < actor.maxcount
            next!(actor.actor, data)
            props.count += 1
            if props.count == actor.maxcount
                complete!(actor)
            end
        end
    end
end

function on_error!(actor::TakeActor, err)
    if !actor.props.isdisposed
        error!(actor.actor, err)
        __dispose(actor)
    end
end

function on_complete!(actor::TakeActor)
    if !actor.props.isdisposed
        complete!(actor.actor)
        __dispose(actor)
    end
end

function __dispose(actor::TakeActor)
    actor.props.isdisposed = true
    unsubscribe!(actor.props.subscription)
end

struct TakeSource{L, S} <: Subscribable{L}
    source :: S
end

function on_subscribe!(observable::TakeSource, actor::TakeActor)
    subscription = subscribe!(observable.source, actor)
    actor.props.subscription = subscription
    return subscription
end

Base.show(io::IO, ::TakeOperator)          = print(io, "TakeOperator()")
Base.show(io::IO, ::TakeProxy{L})  where L = print(io, "TakeProxy($L)")
Base.show(io::IO, ::TakeActor{L})  where L = print(io, "TakeActor($L)")
Base.show(io::IO, ::TakeSource{L}) where L = print(io, "TakeSource($L)")
