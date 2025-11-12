export combineLatestUpdates

import Base: show

"""
    combineLatestUpdates(sources...; strategy = PushEach())
    combineLatestUpdates(sources::S, strategy::G = PushEach()) where { S <: Tuple, U }

`combineLatestUpdates` is a more effiecient version of `combineLatest(sources) + map_to(sources)` operators chain.

# Arguments
- `sources`: input sources
- `strategy`: optional update strategy for batching new values together

Note: `combineLatestUpdates()` completes immediately if `sources` are empty.

See also: [`Subscribable`](@ref), [`subscribe!`](@ref), [`PushEach`](@ref), [`PushEachBut`](@ref), [`PushNew`](@ref), [`PushNewBut`](@ref), [`PushStrategy`](@ref)
"""
function combineLatestUpdates end

combineLatestUpdates(; strategy = PushEach()) =
    error("combineLatestUpdates operator expects at least one inner observable on input")
combineLatestUpdates(args...; strategy = PushEach()) = combineLatestUpdates(args, strategy)
combineLatestUpdates(
    sources::S,
    strategy::G = PushEach(),
    ::Type{R} = S,
    mappingFn::F = identity,
    callbackFn::C = nothing,
) where {S<:Tuple,R,G,F,C} =
    CombineLatestUpdatesObservable{R,S,G,F,C}(sources, strategy, mappingFn, callbackFn)

##

struct CombineLatestUpdatesInnerActor{L,W} <: Actor{L}
    index::Int
    wrapper::W
end

Base.show(io::IO, ::CombineLatestUpdatesInnerActor{L,W}) where {L,W} =
    print(io, "CombineLatestUpdatesInnerActor($L, $I)")

on_next!(actor::CombineLatestUpdatesInnerActor{L,W}, data::L) where {L,W} =
    next_received!(actor.wrapper, data, actor.index)
on_error!(actor::CombineLatestUpdatesInnerActor{L,W}, err) where {L,W} =
    error_received!(actor.wrapper, err, actor.index)
on_complete!(actor::CombineLatestUpdatesInnerActor{L,W}) where {L,W} =
    complete_received!(actor.wrapper, actor.index)

##

struct CombineLatestUpdatesActorWrapper{S,A,G,U,F,C}
    sources::S
    actor::A
    nsize::Int
    strategy::G # Push update strategy
    updates::U # Updates
    subscriptions::Vector{Teardown}
    mappingFn::F
    callbackFn::C
end

function CombineLatestUpdatesActorWrapper(
    sources::S,
    actor::A,
    strategy::G,
    mappingFn::F,
    callbackFn::C,
) where {S,A,G,F,C}
    updates = getustorage(S)
    nsize = length(sources)
    subscriptions = fill!(Vector{Teardown}(undef, nsize), voidTeardown)
    return CombineLatestUpdatesActorWrapper(
        sources,
        actor,
        nsize,
        strategy,
        updates,
        subscriptions,
        mappingFn,
        callbackFn,
    )
end

push_update!(wrapper::CombineLatestUpdatesActorWrapper) =
    push_update!(wrapper.nsize, wrapper.updates, wrapper.strategy)

dispose(wrapper::CombineLatestUpdatesActorWrapper) = begin
    fill_cstatus!(wrapper.updates, true);
    foreach(s -> unsubscribe!(s), wrapper.subscriptions)
end

fill_cstatus!(wrapper::CombineLatestUpdatesActorWrapper, value) =
    fill_cstatus!(wrapper.updates, value)
fill_vstatus!(wrapper::CombineLatestUpdatesActorWrapper, value) =
    fill_vstatus!(wrapper.updates, value)
fill_ustatus!(wrapper::CombineLatestUpdatesActorWrapper, value) =
    fill_ustatus!(wrapper.updates, value)

function next_received!(wrapper::CombineLatestUpdatesActorWrapper, data, index::Int)
    vstatus!(wrapper.updates, index, true)
    ustatus!(wrapper.updates, index, true)
    if all_vstatus(wrapper.updates) && !all_cstatus(wrapper.updates)
        push_update!(wrapper)
        value = wrapper.mappingFn(wrapper.sources)
        next!(wrapper.actor, value)
        if !isnothing(wrapper.callbackFn)
            wrapper.callbackFn(wrapper, value)
        end
    end
end

function error_received!(wrapper::CombineLatestUpdatesActorWrapper, err, index)
    if !(cstatus(wrapper.updates, index))
        dispose(wrapper)
        error!(wrapper.actor, err)
    end
end

function complete_received!(wrapper::CombineLatestUpdatesActorWrapper, index::Int)
    if !all_cstatus(wrapper.updates)
        cstatus!(wrapper.updates, index, true)
        if ustatus(wrapper.updates, index)
            vstatus!(wrapper.updates, index, true)
        end
        if all_cstatus(wrapper.updates) || (!(vstatus(wrapper.updates, index)))
            dispose(wrapper)
            complete!(wrapper.actor)
        end
    end
end

##

@subscribable struct CombineLatestUpdatesObservable{R,S,G,F,C} <: Subscribable{R}
    sources::S
    strategy::G
    mappingFn::F
    callbackFn::C
end

getrecent(observable::CombineLatestUpdatesObservable) = getrecent(observable.sources)

function on_subscribe!(observable::CombineLatestUpdatesObservable, actor)
    wrapper = CombineLatestUpdatesActorWrapper(
        observable.sources,
        actor,
        observable.strategy,
        observable.mappingFn,
        observable.callbackFn,
    )

    __combine_latest_updates_unrolled_fill_subscriptions!(observable.sources, wrapper)

    if all_cstatus(wrapper.updates)
        dispose(wrapper)
    end

    return CombineLatestUpdatesSubscription(wrapper)
end

function __combine_latest_updates_unrolled_fill_subscriptions!(
    ::Tuple{},
    wrapper::CombineLatestUpdatesActorWrapper,
)
    # Fallback for empty `combineLatest`
    complete!(wrapper.actor)
end

@unroll function __combine_latest_updates_unrolled_fill_subscriptions!(
    sources,
    wrapper::W,
) where {W<:CombineLatestUpdatesActorWrapper}
    subscriptions = wrapper.subscriptions
    updates = wrapper.updates
    @unroll for index = 1:length(sources)
        @inbounds source = sources[index]
        @inbounds subscriptions[index] = subscribe!(
            source,
            CombineLatestUpdatesInnerActor{eltype(source),W}(index, wrapper),
        )
        if cstatus(updates, index) && !vstatus(updates, index)
            dispose(wrapper)
            return
        end
    end
end

##

struct CombineLatestUpdatesSubscription{W} <: Teardown
    wrapper::W
end

as_teardown(::Type{<: CombineLatestUpdatesSubscription}) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::CombineLatestUpdatesSubscription)
    dispose(subscription.wrapper)
    return nothing
end

Base.show(io::IO, ::CombineLatestUpdatesObservable{D}) where {D} =
    print(io, "CombineLatestUpdatesObservable($D)")
Base.show(io::IO, ::CombineLatestUpdatesSubscription) =
    print(io, "CombineLatestUpdatesSubscription()")

##
