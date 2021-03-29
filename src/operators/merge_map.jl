export merge_map

import Base: show
import DataStructures: Deque

"""
    merge_map(::Type{R}, mappingFn::F = identity; concurrent::Int = typemax(Int)) where { R, F <: Function }

Creates a `merge_map` operator, which returns an Observable that emits the result of applying the projection
function `mappingFn` to each item emitted by the source Observable and merging the results of the Observables
obtained from this transformation.

# Arguments
- `::Type{R}`: the type of data of output Observables after projection with `mappingFn`
- `mappingFn::F`: projection function with `(data) -> Observable{R}` signature
- `concurrent::Int`: optional, default is `typemax(Int)`, maximum number of input Observables being subscribed to concurrently

# Producing

Stream of type `<: Subscribable{R}`

# Examples
```julia
using Rocket

source = from([ 0, 0 ]) |> merge_map(Int, d -> from([ 1, 2, 3 ], scheduler = AsyncScheduler(0)))
subscribe!(source, logger())
;

# output

[LogActor] Data: 1
[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Data: 2
[LogActor] Data: 3
[LogActor] Data: 3
[LogActor] Completed
```

See also: [`AbstractOperator`](@ref), [`RightTypedOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
merge_map(::Type{R}, mappingFn::F = identity; concurrent::Int = typemax(Int)) where { R, F <: Function } = MergeMapOperator{R, F}(mappingFn, concurrent)

struct MergeMapOperator{R, F} <: RightTypedOperator{R}
    mappingFn  :: F
    concurrent :: Int
end

function on_call!(::Type{L}, ::Type{R}, operator::MergeMapOperator{R, F}, source) where { L, R, F }
    return proxy(R, source, MergeMapProxy{L, R, F}(operator.mappingFn, operator.concurrent))
end

struct MergeMapProxy{L, R, F} <: ActorSourceProxy
    mappingFn  :: F
    concurrent :: Int
end

actor_proxy!(::Type{R}, proxy::MergeMapProxy{L, R, F}, actor::A) where { L, R, F, A } = MergeMapActor{L, R, F, A}(proxy.mappingFn, proxy.concurrent, actor)

# m - main
mutable struct MergeMapActorProps{L}
    msubscription :: Teardown
    ismcompleted  :: Bool
    isdisposed    :: Bool

    active_listeners :: Vector{Any}
    pending_data     :: Deque{L}

    MergeMapActorProps{L}() where L = new(voidTeardown, false, false, Vector{Any}(), Deque{L}())
end

struct MergeMapActor{L, R, F, A} <: Actor{L}
    mappingFn  :: F
    concurrent :: Int
    actor      :: A
    props      :: MergeMapActorProps{L}

    MergeMapActor{L, R, F, A}(mappingFn::F, concurrent::Int, actor::A) where { L, R, F, A } = begin
        return new(mappingFn, concurrent, actor, MergeMapActorProps{L}())
    end
end

getactive(actor::MergeMapActor)  = actor.props.active_listeners
getpending(actor::MergeMapActor) = actor.props.pending_data

pushactive!(actor::MergeMapActor, active)   = push!(getactive(actor), active)
pushpending!(actor::MergeMapActor, pending) = push!(getpending(actor), pending)

isdisposed(actor::MergeMapActor)   = actor.props.isdisposed
ismcompleted(actor::MergeMapActor) = actor.props.ismcompleted
isicompleted(actor::MergeMapActor) = length(getactive(actor)) + length(getpending(actor)) === 0

setmcompleted!(actor::MergeMapActor, value::Bool) = actor.props.ismcompleted = value

function seticompleted!(actor::MergeMapActor, inner)
    filter!(listener -> listener !== inner, getactive(actor))
    if length(getpending(actor)) !== 0
        attach_source_with_map!(actor, popfirst!(getpending(actor)))
    elseif length(getactive(actor)) === 0 && ismcompleted(actor)
        complete!(actor)
    end
end

function attach_source_with_map!(actor::M, data::L) where { L, R, M <: MergeMapActor{L, R} }
    if length(getactive(actor)) < actor.concurrent
        inner = MergeMapInnerActor{R, M}(actor, MergeMapInnerActorProps())
        pushactive!(actor, inner)
        setsubscription!(inner, subscribe!(actor.mappingFn(data), inner))
    else
        pushpending!(actor, data)
    end
end

mutable struct MergeMapInnerActorProps
    subscription :: Teardown

    MergeMapInnerActorProps() = new(voidTeardown)
end

struct MergeMapInnerActor{R, M} <: Actor{R}
    main  :: M
    props :: MergeMapInnerActorProps
end

getsubscription(actor::MergeMapInnerActor)                = actor.props.subscription
setsubscription!(actor::MergeMapInnerActor, subscription) = actor.props.subscription = subscription

on_next!(actor::MergeMapInnerActor{R}, data::R) where R = next!(actor.main.actor, data)
on_error!(actor::MergeMapInnerActor, err)               = error!(actor.main, err)
on_complete!(actor::MergeMapInnerActor)                 = begin
    seticompleted!(actor.main, actor)
end

function on_next!(actor::M, data::L) where { L, R, M <: MergeMapActor{L, R} }
    if !isdisposed(actor)
        attach_source_with_map!(actor, data)
    end
end

function on_error!(actor::MergeMapActor, err)
    if !isdisposed(actor)
        dispose!(actor)
        error!(actor.actor, err)
    end
end

function on_complete!(actor::MergeMapActor)
    setmcompleted!(actor, true)
    if !isdisposed(actor) && isicompleted(actor)
        dispose!(actor)
        complete!(actor.actor)
    end
end

function dispose!(actor::MergeMapActor)
    actor.props.isdisposed = true
    unsubscribe!(actor.props.msubscription)
    for listener in getactive(actor)
        unsubscribe!(getsubscription(listener))
    end
    empty!(getactive(actor))
    empty!(getpending(actor))
end

@subscribable struct MergeMapSource{L, S} <: Subscribable{L}
    source :: S
end

source_proxy!(::Type{R}, proxy::MergeMapProxy{L, R, F}, source::S) where { L, R, F, S } = MergeMapSource{L, S}(source)

function on_subscribe!(source::MergeMapSource, actor::MergeMapActor)
    actor.props.msubscription = subscribe!(source.source, actor)
    return MergeMapSubscription(actor)
end

struct MergeMapSubscription{A} <: Teardown
    actor :: A
end

as_teardown(::Type{ <: MergeMapSubscription }) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::MergeMapSubscription)
    dispose!(subscription.actor)
    return nothing
end

Base.show(io::IO, ::MergeMapOperator{R})   where {    R } = print(io, "MergeMapOperator($R)")
Base.show(io::IO, ::MergeMapProxy{L, R})   where { L, R } = print(io, "MergeMapProxy($L, $R)")
Base.show(io::IO, ::MergeMapActor{L, R})   where { L, R } = print(io, "MergeMapActor($L -> $R)")
Base.show(io::IO, ::MergeMapInnerActor{R}) where {    R } = print(io, "MergeMapInnerActor($R)")
Base.show(io::IO, ::MergeMapSource{S})     where S        = print(io, "MergeMapSource($S)")
Base.show(io::IO, ::MergeMapSubscription)                 = print(io, "MergeMapSubscription()")
