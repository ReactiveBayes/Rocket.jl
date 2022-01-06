export collectLatest

import Base: show

"""
    collectLatest(sources::S, mapping::F = copy) where { S, F }
    collectLatest(::Type{T}, ::Type{R}, sources::S, mapping::F = copy)

Collects values from multible Observables and emits it in one single array every time each inner Observable has a new value.
Reemits errors from inner observables. Completes when all inner observables completes.

# Arguments
- `sources`: input sources
- `mapping`: optional mappingFn applied to an array of emited values, `copy` by default, should return a Vector or an object of type `R`

# Optional arguments
- `::Type{T}`: optional type of emmiting values of inner observables
- `::Type{R}`: optional return type after applying `mapping` to a vector of values

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
function collectLatest(sources::S, mapping::F = copy) where { S, F } 
    T = union_eltype(sources)
    R = similar_typeof(sources, T)
    return CollectLatestObservable{T, S, R, F}(sources, mapping)
end

collectLatest(::Type{T}, ::Type{R}, sources::S, mapping::F = copy) where { T, R, S, F } = CollectLatestObservable{T, S, R, F}(sources, mapping)

## 

struct CollectLatestObservableWrapper{L, A, S, B, T, F}
    actor   :: A
    storage :: S

    cstatus       :: B # Completion status
    vstatus       :: B # Values status
    ustatus       :: B # Updates status
    subscriptions :: T
    mapping       :: F

    CollectLatestObservableWrapper{L, A, S, B, T, F}(actor::A, storage::S, cstatus::B, vstatus::B, ustatus::B, subscriptions::T, mapping::F) where {L, A, S, B, T, F} = begin
        return new(actor, storage, cstatus, vstatus, ustatus, subscriptions, mapping)
    end
end

function CollectLatestObservableWrapper(::Type{L}, actor::A, storage::S, mapping::F) where { L, A, S, F } 
    nsize         = size(storage)
    cstatus       = falses(nsize)
    vstatus       = falses(nsize)
    ustatus       = falses(nsize)
    subscriptions = fill!(similar(storage, Subscription), noopSubscription)
    return CollectLatestObservableWrapper{L, A, S, typeof(cstatus), typeof(subscriptions), F}(actor, storage, cstatus, vstatus, ustatus, subscriptions, mapping)
end

cstatus(wrapper::CollectLatestObservableWrapper, index::CartesianIndex) = @inbounds wrapper.cstatus[index]
vstatus(wrapper::CollectLatestObservableWrapper, index::CartesianIndex) = @inbounds wrapper.vstatus[index]
ustatus(wrapper::CollectLatestObservableWrapper, index::CartesianIndex) = @inbounds wrapper.ustatus[index]

dispose(wrapper::CollectLatestObservableWrapper) = begin fill!(wrapper.cstatus, true); foreach(s -> unsubscribe!(s), wrapper.subscriptions) end

struct CollectLatestObservableInnerActor{I <: CartesianIndex, W}
    index   :: I
    wrapper :: W
end

Base.show(io::IO, ::CollectLatestObservableInnerActor) = print(io, "CollectedObservableInnerActor()")

on_next!(actor::CollectLatestObservableInnerActor, data) = next_received!(actor.wrapper, data, actor.index)
on_error!(actor::CollectLatestObservableInnerActor, err) = error_received!(actor.wrapper, err, actor.index)
on_complete!(actor::CollectLatestObservableInnerActor)   = complete_received!(actor.wrapper, actor.index)

function next_received!(wrapper::CollectLatestObservableWrapper, data, index::CartesianIndex)
    @inbounds wrapper.storage[index] = data
    @inbounds wrapper.vstatus[index] = true
    @inbounds wrapper.ustatus[index] = true
    if all(wrapper.vstatus) && !all(wrapper.cstatus)
        unsafe_copyto!(wrapper.vstatus, 1, wrapper.cstatus, 1, length(wrapper.vstatus))
        next!(wrapper.actor, wrapper.mapping(wrapper.storage))
    end
end

function error_received!(wrapper::CollectLatestObservableWrapper, err, index::CartesianIndex)
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

struct CollectLatestObservable{T, S, R, F} <: Subscribable{R}
    sources :: S
    mapping :: F
end

function on_subscribe!(observable::CollectLatestObservable{L}, actor::A) where { L, A }
    sources = observable.sources
    storage = similar(sources, L)
    wrapper = CollectLatestObservableWrapper(L, actor, storage, observable.mapping)
    W       = typeof(wrapper)
    
    indices = CartesianIndices(axes(sources))
    I       = eltype(indices)

    for index in indices
        @inbounds wrapper.subscriptions[index] = subscribe!(sources[index], CollectLatestObservableInnerActor{I, W}(index, wrapper))
        if cstatus(wrapper, index) === true && vstatus(wrapper, index) === false
            dispose(wrapper)
            break
        end
    end

    if all(wrapper.cstatus)
        dispose(wrapper)
    end

    return CollectLatestSubscription(wrapper)
end

##

struct CollectLatestSubscription{W} <: Subscription
    wrapper :: W
end

function on_unsubscribe!(subscription::CollectLatestSubscription)
    dispose(subscription.wrapper)
    return nothing
end

Base.show(io::IO, ::CollectLatestObservable{T, S, R}) where { T, S, R }  = print(io, "CollectLatestObservable($R)")
Base.show(io::IO, ::CollectLatestSubscription)                           = print(io, "CollectLatestSubscription()")