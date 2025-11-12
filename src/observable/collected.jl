export collectLatest

import Base: show

"""
    collectLatest(sources::S, mappingFn::F = copy, callbackFn::C = nothing)
    collectLatest(::Type{T}, ::Type{R}, sources::S, mappingFn::F = copy, callbackFn::C = nothing)

Collects values from multible Observables and emits it in one single array every time each inner Observable has a new value.
Reemits errors from inner observables. Completes when all inner observables completes.

# Arguments
- `sources`: input sources
- `mappingFn`: optional mappingFn applied to an array of emited values, `copy` by default, should return a Vector
- `callbackFn`: optional callback function, which is called right after `mappingFn` has been evaluated, accepts the state of the inner actor and the computed value, `nothing` by default

Note: `collectLatest` completes immediately if `sources` are empty.

# Optional arguments
- `::Type{T}`: optional type of emmiting values of inner observables
- `::Type{R}`: optional return type after applying `mappingFn` to a vector of values

# Examples
```jldoctest
using Rocket

collected = collectLatest([ of(1), from([ 1, 2 ]) ])

subscribe!(collected, logger())
;

# output

[LogActor] Data: [1, 1]
[LogActor] Data: [1, 2]
[LogActor] Completed
```

See also: [`Subscribable`](@ref), [`subscribe!`](@ref), [`combineLatest`](@ref)
"""
function collectLatest(
    sources::S,
    mappingFn::F = copy,
    callbackFn::C = nothing,
) where {S,F,C}
    T = union_type(sources)
    R = similar_typeof(sources, T)
    return CollectLatestObservable{T,S,R,F,C}(sources, mappingFn, callbackFn)
end

collectLatest(
    ::Type{T},
    ::Type{R},
    sources::S,
    mappingFn::F = copy,
    callbackFn::C = nothing,
) where {T,R,S,F,C} = CollectLatestObservable{T,S,R,F,C}(sources, mappingFn, callbackFn)

## 

struct CollectLatestObservableWrapper{L,A,S,B,T,F,C}
    actor::A
    storage::S

    cstatus::B # Completion status
    vstatus::B # Values status
    ustatus::B # Updates status
    subscriptions::T
    mappingFn::F
    callbackFn::C

    CollectLatestObservableWrapper{L,A,S,B,T,F,C}(
        actor::A,
        storage::S,
        cstatus::B,
        vstatus::B,
        ustatus::B,
        subscriptions::T,
        mappingFn::F,
        callbackFn::C,
    ) where {L,A,S,B,T,F,C} = begin
        return new(
            actor,
            storage,
            cstatus,
            vstatus,
            ustatus,
            subscriptions,
            mappingFn,
            callbackFn,
        )
    end
end

function CollectLatestObservableWrapper(
    ::Type{L},
    actor::A,
    storage::S,
    mappingFn::F,
    callbackFn::C,
) where {L,A,S,F,C}
    nsize = size(storage)
    cstatus = falses(nsize)
    vstatus = falses(nsize)
    ustatus = falses(nsize)
    subscriptions = fill!(similar(storage, Teardown), voidTeardown)
    return CollectLatestObservableWrapper{L,A,S,typeof(cstatus),typeof(subscriptions),F,C}(
        actor,
        storage,
        cstatus,
        vstatus,
        ustatus,
        subscriptions,
        mappingFn,
        callbackFn,
    )
end

cstatus(wrapper::CollectLatestObservableWrapper, index::CartesianIndex) =
    @inbounds wrapper.cstatus[index]
vstatus(wrapper::CollectLatestObservableWrapper, index::CartesianIndex) =
    @inbounds wrapper.vstatus[index]
ustatus(wrapper::CollectLatestObservableWrapper, index::CartesianIndex) =
    @inbounds wrapper.ustatus[index]

fill_cstatus!(wrapper::CollectLatestObservableWrapper, value) =
    fill!(wrapper.cstatus, value)
fill_vstatus!(wrapper::CollectLatestObservableWrapper, value) =
    fill!(wrapper.vstatus, value)
fill_ustatus!(wrapper::CollectLatestObservableWrapper, value) =
    fill!(wrapper.ustatus, value)

dispose(wrapper::CollectLatestObservableWrapper) = begin
    fill!(wrapper.cstatus, true);
    foreach(s -> unsubscribe!(s), wrapper.subscriptions)
end

struct CollectLatestObservableInnerActor{L,I<:CartesianIndex,W} <: Actor{L}
    index::I
    wrapper::W
end

Base.show(io::IO, ::CollectLatestObservableInnerActor{L}) where {L} =
    print(io, "CollectedObservableInnerActor($L)")

on_next!(actor::CollectLatestObservableInnerActor{L}, data::L) where {L} =
    next_received!(actor.wrapper, data, actor.index)
on_error!(actor::CollectLatestObservableInnerActor, err) =
    error_received!(actor.wrapper, err, actor.index)
on_complete!(actor::CollectLatestObservableInnerActor) =
    complete_received!(actor.wrapper, actor.index)

function next_received!(
    wrapper::CollectLatestObservableWrapper,
    data,
    index::CartesianIndex,
)
    @inbounds wrapper.storage[index] = data
    @inbounds wrapper.vstatus[index] = true
    @inbounds wrapper.ustatus[index] = true
    if all(wrapper.vstatus) && !all(wrapper.cstatus)
        unsafe_copyto!(wrapper.vstatus, 1, wrapper.cstatus, 1, length(wrapper.vstatus))
        value = wrapper.mappingFn(wrapper.storage)
        next!(wrapper.actor, value)
        if !isnothing(wrapper.callbackFn)
            wrapper.callbackFn(wrapper, value)
        end
    end
end

function error_received!(
    wrapper::CollectLatestObservableWrapper,
    err,
    index::CartesianIndex,
)
    if !(@inbounds wrapper.cstatus[index])
        dispose(wrapper)
        error!(wrapper.actor, err)
    end
end

function complete_received!(wrapper::CollectLatestObservableWrapper, index::CartesianIndex)
    if !all(wrapper.cstatus)
        @inbounds wrapper.cstatus[index] = true
        if ustatus(wrapper, index)
            @inbounds wrapper.vstatus[index] = true
        end
        if all(wrapper.cstatus) || (@inbounds wrapper.vstatus[index] === false)
            dispose(wrapper)
            complete!(wrapper.actor)
        end
    end
end

## 

@subscribable struct CollectLatestObservable{T,S,R,F,C} <: Subscribable{R}
    sources::S
    mappingFn::F
    callbackFn::C
end

function on_subscribe!(observable::CollectLatestObservable{L}, actor::A) where {L,A}
    sources = observable.sources
    storage = similar(sources, L)
    wrapper = CollectLatestObservableWrapper(
        L,
        actor,
        storage,
        observable.mappingFn,
        observable.callbackFn,
    )
    W = typeof(wrapper)

    if length(sources) !== 0
        for index in CartesianIndices(axes(sources))
            @inbounds wrapper.subscriptions[index] = subscribe!(
                sources[index],
                CollectLatestObservableInnerActor{L,typeof(index),W}(index, wrapper),
            )
            if cstatus(wrapper, index) === true && vstatus(wrapper, index) === false
                dispose(wrapper)
                break
            end
        end
    else
        complete!(actor)
    end

    if all(wrapper.cstatus)
        dispose(wrapper)
    end

    return CollectLatestSubscription(wrapper)
end

##

struct CollectLatestSubscription{W} <: Teardown
    wrapper::W
end

as_teardown(::Type{<: CollectLatestSubscription}) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::CollectLatestSubscription)
    dispose(subscription.wrapper)
    return nothing
end

Base.show(io::IO, ::CollectLatestObservable{D}) where {D} =
    print(io, "CollectLatestObservable($D)")
Base.show(io::IO, ::CollectLatestSubscription) = print(io, "CollectLatestSubscription()")
