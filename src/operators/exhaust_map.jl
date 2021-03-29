export exhaust_map

import Base: show

"""
    exhaust_map(::Type{R}, mappingFn::F = identity) where { R, F <: Function }

Creates a `exhaust_map` operator, which returns an Observable containing projected Observables of each
item of the source, ignoring projected Observables that start before their preceding Observable has completed.
Essentially it projects each source value to an Observable which is merged in the output Observable only
if the previous projected Observable has completed.

# Arguments
- `::Type{R}`: the type of data of output Observables after projection with `mappingFn`
- `mappingFn::F`: projection function with `(data) -> Observable{R}` signature

# Producing

Stream of type `<: Subscribable{R}`

# Examples
```julia
using Rocket

source = from([ 0, 0 ]) |> async() |> exhaust_map(Int, d -> from([ 1, 2 ]) |> async())
subscribe!(source, logger())
;

# output

[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Completed
```

See also: [`AbstractOperator`](@ref), [`RightTypedOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
exhaust_map(::Type{R}, mappingFn::F = identity) where { R, F <: Function } = ExhaustMapOperator{R, F}(mappingFn)

struct ExhaustMapOperator{R, F} <: RightTypedOperator{R}
    mappingFn :: F
end

function on_call!(::Type{L}, ::Type{R}, operator::ExhaustMapOperator{R, F}, source) where { L, R, F }
    return proxy(R, source, ExhaustMapProxy{L, R, F}(operator.mappingFn))
end

struct ExhaustMapProxy{L, R, F} <: ActorSourceProxy
    mappingFn :: F
end

actor_proxy!(::Type{R}, proxy::ExhaustMapProxy{L, R, F}, actor::A) where { L, R, F, A } = ExhaustMapActor{L, R, F, A}(proxy.mappingFn, actor)

# m - main
# i - inner
mutable struct ExhaustMapActorProps
    msubscription :: Teardown
    isubscription :: Teardown
    ismcompleted  :: Bool
    isicompleted  :: Bool
    isdisposed    :: Bool

    ExhaustMapActorProps() = new(voidTeardown, voidTeardown, false, true, false)
end

struct ExhaustMapActor{L, R, F, A} <: Actor{L}
    mappingFn :: F
    actor     :: A
    props     :: ExhaustMapActorProps

    ExhaustMapActor{L, R, F, A}(mappingFn::F, actor::A) where { L, R, F, A } = new(mappingFn, actor, ExhaustMapActorProps())
end

ismcompleted(actor::ExhaustMapActor) = actor.props.ismcompleted
isicompleted(actor::ExhaustMapActor) = actor.props.isicompleted

setmcompleted!(actor::ExhaustMapActor, value::Bool) = actor.props.ismcompleted = value
seticompleted!(actor::ExhaustMapActor, value::Bool) = actor.props.isicompleted = value

isdisposed(actor::ExhaustMapActor)   = actor.props.isdisposed

struct ExhaustMapInnerActor{R, S} <: Actor{R}
    main :: S
end

on_next!(actor::ExhaustMapInnerActor{R}, data::R) where R = next!(actor.main.actor, data)
on_error!(actor::ExhaustMapInnerActor,   err)             = error!(actor.main, err)
on_complete!(actor::ExhaustMapInnerActor)                 = begin
    actor.main.props.isubscription = voidTeardown
    seticompleted!(actor.main, true)
    if ismcompleted(actor.main)
        complete!(actor.main)
    end
end

function on_next!(actor::S, data::L) where { L, R, S <: ExhaustMapActor{L, R} }
    if !isdisposed(actor)
        if isicompleted(actor)
            unsubscribe!(actor.props.isubscription)
            seticompleted!(actor, false)
            actor.props.isubscription = subscribe!(actor.mappingFn(data), ExhaustMapInnerActor{R, S}(actor))
        end
    end
end

function on_error!(actor::ExhaustMapActor, err)
    if !isdisposed(actor)
        dispose!(actor)
        error!(actor.actor, err)
    end
end

function on_complete!(actor::ExhaustMapActor)
    setmcompleted!(actor, true)
    if !isdisposed(actor) && isicompleted(actor)
        dispose!(actor)
        complete!(actor.actor)
    end
end

function dispose!(actor::ExhaustMapActor)
    actor.props.isdisposed = true
    unsubscribe!(actor.props.msubscription)
    unsubscribe!(actor.props.isubscription)
end

@subscribable struct ExhaustMapSource{L, S} <: Subscribable{L}
    source :: S
end

source_proxy!(::Type{R}, proxy::ExhaustMapProxy{L, R, F}, source::S) where { L, R, F, S } = ExhaustMapSource{L, S}(source)

function on_subscribe!(source::ExhaustMapSource, actor::ExhaustMapActor)
    actor.props.msubscription = subscribe!(source.source, actor)
    return ExhaustMapSubscription(actor)
end

struct ExhaustMapSubscription{A} <: Teardown
    actor :: A
end

as_teardown(::Type{ <: ExhaustMapSubscription }) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::ExhaustMapSubscription)
    dispose!(subscription.actor)
    return nothing
end


Base.show(io::IO, ::ExhaustMapOperator{R})   where {    R } = print(io, "ExhaustMapOperator($R)")
Base.show(io::IO, ::ExhaustMapProxy{L, R})   where { L, R } = print(io, "ExhaustMapProxy($L, $R)")
Base.show(io::IO, ::ExhaustMapActor{L, R})   where { L, R } = print(io, "ExhaustMapActor($L -> $R)")
Base.show(io::IO, ::ExhaustMapInnerActor{R}) where {    R } = print(io, "ExhaustMapInnerActor($R)")
Base.show(io::IO, ::ExhaustMapSource{S})     where S        = print(io, "ExhaustMapSource($S)")
Base.show(io::IO, ::ExhaustMapSubscription)                 = print(io, "ExhaustMapSubscription()")
