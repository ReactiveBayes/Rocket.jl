export switch_map

import Base: show

"""
    switch_map(::Type{R}, mappingFn::F) where { R, F <: Function }

Creates a `switch_map` operator, which returns an Observable that emits items based on applying a function `mappingFn` that you supply to each item
emitted by the source Observable, where that function returns an (so-called "inner") Observable. Each time it observes one of these inner Observables,
the output Observable begins emitting the items emitted by that inner Observable. When a new inner Observable is emitted, `switch_map` stops emitting
items from the earlier-emitted inner Observable and begins emitting items from the new one. It continues to behave like this for
subsequent inner Observables.

# Arguments
- `::Type{R}`: the type of data of output Observables after projection with `mappingFn`
- `mappingFn::F`: porjection function with `(data::Observable{L}) -> Observable{R}` signature, where L is type of data in "inner" observables

# Producing

Stream of type `<: Subscribable{R}`

# Examples
```jldoctest
using Rocket

source = from([ of(1), of(2), of(3) ])
subscribe!(source |> switch_map(Int), logger())
;

# output

[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Data: 3
[LogActor] Completed
```

```jldoctest
using Rocket

source = from([ 1, 2, 3 ])
subscribe!(source |> switch_map(Float64, (d) -> of(convert(Float64, d ^ 2))), logger())
;

# output

[LogActor] Data: 1.0
[LogActor] Data: 4.0
[LogActor] Data: 9.0
[LogActor] Completed
```

See also: [`AbstractOperator`](@ref), [`RightTypedOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
switch_map(::Type{R}, mappingFn::F = identity; inner_complete::Bool = false) where { R, F <: Function } = SwitchMapOperator{R, F}(mappingFn, inner_complete)

struct SwitchMapOperator{R, F} <: RightTypedOperator{R}
    mappingFn      :: F
    inner_complete :: Bool
end

function on_call!(::Type{L}, ::Type{R}, operator::SwitchMapOperator{R, F}, source) where { L, R, F }
    return proxy(R, source, SwitchMapProxy{L, R, F}(operator.mappingFn, operator.inner_complete))
end

struct SwitchMapProxy{L, R, F} <: ActorSourceProxy
    mappingFn      :: F
    inner_complete :: Bool
end

actor_proxy!(proxy::SwitchMapProxy{L, R, F}, actor::A) where { L, R, F, A } = SwitchMapActor{L, R, F, A}(proxy.mappingFn, proxy.inner_complete, actor)

mutable struct SwitchMapActorProps
    msubscription :: Teardown
    isubscription :: Teardown
    isdisposed    :: Bool

    SwitchMapActorProps() = new(VoidTeardown(), VoidTeardown(), false)
end

struct SwitchMapActor{L, R, F, A} <: Actor{L}
    mappingFn      :: F
    inner_complete :: Bool
    actor          :: A
    props          :: SwitchMapActorProps

    SwitchMapActor{L, R, F, A}(mappingFn::F, inner_complete::Bool, actor::A) where { L, R, F, A } = new(mappingFn, inner_complete, actor, SwitchMapActorProps())
end

isinner_complete(actor::SwitchMapActor) = actor.inner_complete
isdisposed(actor::SwitchMapActor)       = actor.props.isdisposed

struct SwitchMapInnerActor{R, S} <: Actor{R}
    switch :: S
end

on_next!(actor::SwitchMapInnerActor{R}, data::R) where R = next!(actor.switch.actor, data)
on_error!(actor::SwitchMapInnerActor,   err)             = error!(actor.switch, err)
on_complete!(actor::SwitchMapInnerActor)                 = begin
    if isinner_complete(actor.switch)
        dispose(actor.switch)
        complete!(actor.switch.actor)
    end
end

function on_next!(actor::S, data::L) where { L, R, S <: SwitchMapActor{L, R} }
    if !isdisposed(actor)
        unsubscribe!(actor.props.isubscription)
        actor.props.isubscription = subscribe!(actor.mappingFn(data), SwitchMapInnerActor{R, S}(actor))
    end
end

function on_error!(actor::SwitchMapActor, err)
    if !isdisposed(actor)
        dispose(actor)
        error!(actor.actor, err)
    end
end

function on_complete!(actor::SwitchMapActor)
    if !isdisposed(actor) && !isinner_complete(actor)
        dispose(actor)
        complete!(actor.actor)
    end
end

function dispose(actor::SwitchMapActor)
    actor.props.isdisposed = true
    unsubscribe!(actor.props.msubscription)
    unsubscribe!(actor.props.isubscription)
end

struct SwitchMapSource{L, S} <: Subscribable{L}
    source :: S
end

source_proxy!(proxy::SwitchMapProxy{L, R, F}, source::S) where { L, R, F, S } = SwitchMapSource{L, S}(source)

function on_subscribe!(source::SwitchMapSource, actor::SwitchMapActor)
    actor.props.msubscription = subscribe!(source.source, actor)
    return SwitchMapSubscription(actor)
end

struct SwitchMapSubscription{A} <: Teardown
    actor :: A
end

as_teardown(::Type{<:SwitchMapSubscription}) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::SwitchMapSubscription)
    unsubscribe!(subscription.actor.props.msubscription)
    unsubscribe!(subscription.actor.props.isubscription)
end


Base.show(io::IO, ::SwitchMapOperator{R})   where {    R } = print(io, "SwitchMapOperator($R)")
Base.show(io::IO, ::SwitchMapProxy{L, R})   where { L, R } = print(io, "SwitchMapProxy($L -> $R)")
Base.show(io::IO, ::SwitchMapActor{L, R})   where { L, R } = print(io, "SwitchMapActor($L -> $R)")
Base.show(io::IO, ::SwitchMapInnerActor{R}) where {    R } = print(io, "SwitchMapInnerActor($R)")
Base.show(io::IO, ::SwitchMapSource{S})     where S        = print(io, "SwitchMapSource($S)")
Base.show(io::IO, ::SwitchMapSubscription)                 = print(io, "SwitchMapSubscription()")
