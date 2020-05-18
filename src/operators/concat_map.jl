export concat_map

import Base: show
import DataStructures: Deque

"""
    concat_map(::Type{R}, mappingFn::F = identity) where { R, F <: Function }

Creates a `concat_map` operator, which returns an Observable that emits the result of applying the
projection function to each item emitted by the source Observable and taking values from each
projected inner Observable sequentially. Essentialy it projects each source value to an Observable which is
merged in the output Observable, in a serialized fashion waiting for each one to complete before merging the next.

# Arguments
- `::Type{R}`: the type of data of output Observables after projection with `mappingFn`
- `mappingFn::F`: projection function with `(data) -> Observable{R}` signature

# Producing

Stream of type `<: Subscribable{R}`

# Examples
```julia
using Rocket

source = from([ 0, 0 ]) |> concat_map(Int, d -> from([ 1, 2, 3 ], scheduler = AsyncScheduler(0)))
subscribe!(source, logger())
;

# output

[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Data: 3
[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Data: 3
[LogActor] Completed
```

See also: [`AbstractOperator`](@ref), [`RightTypedOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
concat_map(::Type{R}, mappingFn::F = identity) where { R, F <: Function } = ConcatMapOperator{R, F}(mappingFn)

struct ConcatMapOperator{R, F} <: RightTypedOperator{R}
    mappingFn :: F
end

function on_call!(::Type{L}, ::Type{R}, operator::ConcatMapOperator{R, F}, source) where { L, R, F }
    return proxy(R, source, ConcatMapProxy{L, R, F}(operator.mappingFn))
end

struct ConcatMapProxy{L, R, F} <: ActorSourceProxy
    mappingFn :: F
end

actor_proxy!(::Type{R}, proxy::ConcatMapProxy{L, R, F}, actor::A) where { L, R, F, A } = ConcatMapActor{L, R, F, A}(proxy.mappingFn, actor)

# m - main
mutable struct ConcatMapActorProps{L}
    msubscription :: Teardown
    ismcompleted  :: Bool
    isdisposed    :: Bool

    active_listener :: Union{Nothing, Any}
    pending_data    :: Deque{L}

    ConcatMapActorProps{L}() where L = new(voidTeardown, false, false, nothing, Deque{L}())
end

struct ConcatMapActor{L, R, F, A} <: Actor{L}
    mappingFn  :: F
    actor      :: A
    props      :: ConcatMapActorProps{L}

    ConcatMapActor{L, R, F, A}(mappingFn::F, actor::A) where { L, R, F, A } = begin
        return new(mappingFn, actor, ConcatMapActorProps{L}())
    end
end

getactive(actor::ConcatMapActor)  = actor.props.active_listener
getpending(actor::ConcatMapActor) = actor.props.pending_data

setactive!(actor::ConcatMapActor, active)    = actor.props.active_listener = active
pushpending!(actor::ConcatMapActor, pending) = push!(getpending(actor), pending)

isdisposed(actor::ConcatMapActor)   = actor.props.isdisposed
ismcompleted(actor::ConcatMapActor) = actor.props.ismcompleted
isicompleted(actor::ConcatMapActor) = getactive(actor) === nothing && length(getpending(actor)) === 0

setmcompleted!(actor::ConcatMapActor, value::Bool) = actor.props.ismcompleted = value

function seticompleted!(actor::ConcatMapActor, inner)
    setactive!(actor, nothing)
    if length(getpending(actor)) !== 0
        attach_source_with_map!(actor, popfirst!(getpending(actor)))
    elseif ismcompleted(actor)
        complete!(actor)
    end
end

function attach_source_with_map!(actor::M, data::L) where { L, R, M <: ConcatMapActor{L, R} }
    if getactive(actor) === nothing
        inner = ConcatMapInnerActor{R, M}(actor, ConcatMapInnerActorProps())
        setactive!(actor, inner)
        setsubscription!(inner, subscribe!(actor.mappingFn(data), inner))
    else
        pushpending!(actor, data)
    end
end

mutable struct ConcatMapInnerActorProps
    subscription :: Teardown

    ConcatMapInnerActorProps() = new(voidTeardown)
end

struct ConcatMapInnerActor{R, M} <: Actor{R}
    main  :: M
    props :: ConcatMapInnerActorProps
end

getsubscription(actor::ConcatMapInnerActor)                = actor.props.subscription
setsubscription!(actor::ConcatMapInnerActor, subscription) = actor.props.subscription = subscription

on_next!(actor::ConcatMapInnerActor{R}, data::R) where R = next!(actor.main.actor, data)
on_error!(actor::ConcatMapInnerActor, err)               = error!(actor.main, err)
on_complete!(actor::ConcatMapInnerActor)                 = begin
    seticompleted!(actor.main, actor)
end

function on_next!(actor::M, data::L) where { L, R, M <: ConcatMapActor{L, R} }
    if !isdisposed(actor)
        attach_source_with_map!(actor, data)
    end
end

function on_error!(actor::ConcatMapActor, err)
    if !isdisposed(actor)
        dispose!(actor)
        error!(actor.actor, err)
    end
end

function on_complete!(actor::ConcatMapActor)
    setmcompleted!(actor, true)
    if !isdisposed(actor) && isicompleted(actor)
        dispose!(actor)
        complete!(actor.actor)
    end
end

function dispose!(actor::ConcatMapActor)
    actor.props.isdisposed = true
    unsubscribe!(actor.props.msubscription)
    active = getactive(actor)
    if active !== nothing
        unsubscribe!(getsubscription(active))
    end
    setactive!(actor, nothing)
    empty!(getpending(actor))
end

struct ConcatMapSource{L, S} <: Subscribable{L}
    source :: S
end

source_proxy!(::Type{R}, proxy::ConcatMapProxy{L, R, F}, source::S) where { L, R, F, S } = ConcatMapSource{L, S}(source)

function on_subscribe!(source::ConcatMapSource, actor::ConcatMapActor)
    actor.props.msubscription = subscribe!(source.source, actor)
    return ConcatMapSubscription(actor)
end

struct ConcatMapSubscription{A} <: Teardown
    actor :: A
end

as_teardown(::Type{ <: ConcatMapSubscription }) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::ConcatMapSubscription)
    dispose!(subscription.actor)
    return nothing
end

Base.show(io::IO, ::ConcatMapOperator{R})   where {    R } = print(io, "ConcatMapOperator($R)")
Base.show(io::IO, ::ConcatMapProxy{L, R})   where { L, R } = print(io, "ConcatMapProxy($L, $R)")
Base.show(io::IO, ::ConcatMapActor{L, R})   where { L, R } = print(io, "ConcatMapActor($L -> $R)")
Base.show(io::IO, ::ConcatMapInnerActor{R}) where {    R } = print(io, "ConcatMapInnerActor($R)")
Base.show(io::IO, ::ConcatMapSource{S})     where S        = print(io, "ConcatMapSource($S)")
Base.show(io::IO, ::ConcatMapSubscription)                 = print(io, "ConcatMapSubscription()")
