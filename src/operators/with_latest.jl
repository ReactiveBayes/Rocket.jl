export with_latest

import Base: show

"""

    with_latest(sources...)

Creates a with_latest operator, which combines the source Observable with other
Observables to create an Observable whose values are calculated from the latest values of each, only when the source emits.

# Examples

```jldoctest
using Rocket

source = of(1)
subscribe!(source |> with_latest(from(1:5)), logger())
;

# output

[LogActor] Data: (1, 5)
[LogActor] Completed
```

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref)
"""
with_latest() = error("with_latest operator expects at least one inner observable on input")
with_latest(sources...) = with_latest(sources)
with_latest(sources::S) where {S<:Tuple} = WithLatestOperator{S}(sources)

##

struct WithLatestOperator{S} <: InferableOperator
    sources::S
end

function on_call!(
    ::Type{L},
    ::Type{R},
    operator::WithLatestOperator{S},
    source::M,
) where {L,R,M,S}
    return WithLatestObservable{R,M,S}(source, operator.sources)
end

operator_right(operator::WithLatestOperator, ::Type{L}) where {L} =
    Tuple{L,combined_type(operator.sources).parameters...}

Base.show(io::IO, ::WithLatestOperator) = print(io, "WithLatestOperator()")

##

struct WithLatestInnerActor{L,W,I} <: Actor{L}
    wrapper::W
end

Base.show(io::IO, inner::WithLatestInnerActor{L,W,I}) where {L,W,I} =
    print(io, "WithLatestInnerActor($L, $I)")

on_next!(actor::WithLatestInnerActor{L,W,I}, data::L) where {L,W,I} =
    next_received!(actor.wrapper, data, Val{I}())
on_error!(actor::WithLatestInnerActor{L,W,I}, err) where {L,W,I} =
    error_received!(actor.wrapper, err, Val{I}())
on_complete!(actor::WithLatestInnerActor{L,W,I}) where {L,W,I} =
    complete_received!(actor.wrapper, Val{I}())

##

struct WithLatestActorWrapper{S,A}
    storage::S
    actor::A

    nsize::Int
    cstatus::BitArray{1} # Completion status
    vstatus::BitArray{1} # Values status

    subscriptions::Vector{Teardown}

    WithLatestActorWrapper{S,A}(storage::S, actor::A) where {S,A} = begin
        nsize = length(storage)
        cstatus = falses(nsize)
        vstatus = falses(nsize)
        subscriptions = fill!(Vector{Teardown}(undef, nsize), voidTeardown)
        return new(storage, actor, nsize, cstatus, vstatus, subscriptions)
    end
end

cstatus(wrapper::WithLatestActorWrapper, index) = wrapper.cstatus[index]
vstatus(wrapper::WithLatestActorWrapper, index) = wrapper.vstatus[index]

secondary_cstatus(wrapper::WithLatestActorWrapper) =
    view(wrapper.cstatus, 2:length(wrapper.cstatus))
secondary_vstatus(wrapper::WithLatestActorWrapper) =
    view(wrapper.vstatus, 2:length(wrapper.vstatus))

function dispose(wrapper::WithLatestActorWrapper)
    fill!(wrapper.cstatus, true)
    foreach(s -> unsubscribe!(s), wrapper.subscriptions)
end

function next_received!(wrapper::WithLatestActorWrapper, data, index::Val{I}) where {I}
    setstorage!(wrapper.storage, data, index)
    wrapper.vstatus[I] = true
    if I === 1 && all(wrapper.vstatus) && !all(wrapper.cstatus)
        next!(wrapper.actor, snapshot(wrapper.storage))
    end
end

function error_received!(wrapper::WithLatestActorWrapper, err, index::Val{I}) where {I}
    if !cstatus(wrapper, I)
        dispose(wrapper)
        error!(wrapper.actor, err)
    end
end

function complete_received!(wrapper::WithLatestActorWrapper, ::Val{I}) where {I}
    if !all(wrapper.cstatus)
        wrapper.cstatus[I] = true
        if I === 1 || all(wrapper.cstatus) || wrapper.vstatus[I] === false
            dispose(wrapper)
            complete!(wrapper.actor)
        end
    end
end

##

@subscribable struct WithLatestObservable{T,M,S} <: Subscribable{T}
    main::M
    secondary::S
end

function on_subscribe!(observable::WithLatestObservable{T,M,S}, actor::A) where {T,M,S,A}
    storage = getmstorage(T)
    wrapper = WithLatestActorWrapper{typeof(storage),A}(storage, actor)

    for (index, source) in enumerate(observable.secondary)
        wrapper.subscriptions[index+1] = subscribe!(
            source,
            WithLatestInnerActor{eltype(source),typeof(wrapper),index + 1}(wrapper),
        )
        if cstatus(wrapper, index + 1) === true && vstatus(wrapper, index + 1) === false
            dispose(wrapper)
            break
        end
    end

    if !all(secondary_cstatus(wrapper)) || all(secondary_vstatus(wrapper))
        source = observable.main
        wrapper.subscriptions[1] = subscribe!(
            source,
            WithLatestInnerActor{eltype(source),typeof(wrapper),1}(wrapper),
        )
    end

    return WithLatestSubscription(wrapper)
end

##

struct WithLatestSubscription{W} <: Teardown
    wrapper::W
end

as_teardown(::Type{<: WithLatestSubscription}) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::WithLatestSubscription)
    dispose(subscription.wrapper)
    return nothing
end

Base.show(io::IO, ::WithLatestObservable{D}) where {D} =
    print(io, "WithLatestObservable($D)")
Base.show(io::IO, ::WithLatestSubscription) = print(io, "WithLatestSubscription()")

##
