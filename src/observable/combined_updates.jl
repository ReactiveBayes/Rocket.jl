export combineLatestUpdates

import Base: show

"""
    combineLatestUpdates(sources...; strategy = PushEach())
    combineLatestUpdates(sources::S, strategy::G = PushEach()) where { S <: Tuple, U }

`combineLatestUpdates` is a more effiecient version of `combineLatest(sources) + map_to(sources)` operators chain.

# Arguments
- `sources`: input sources
- `strategy`: optional update strategy for batching new values together

See also: [`Subscribable`](@ref), [`subscribe!`](@ref), [`PushEach`](@ref), [`PushEachBut`](@ref), [`PushNew`](@ref), [`PushNewBut`](@ref), [`PushStrategy`](@ref)
"""
function combineLatestUpdates end

combineLatestUpdates(; strategy = PushEach())                                       = error("combineLatestUpdates operator expects at least one inner observable on input")
combineLatestUpdates(args...; strategy = PushEach())                                = combineLatestUpdates(args, strategy)
combineLatestUpdates(sources::S, strategy::G = PushEach()) where { S <: Tuple, G }  = CombineLatestUpdatesObservable{S, G}(sources, strategy)

##

struct CombineLatestUpdatesInnerActor{W}
    index   :: Int
    wrapper :: W
end

Base.show(io::IO, ::CombineLatestUpdatesInnerActor) = print(io, "CombineLatestUpdatesInnerActor()")

on_next!(actor::CombineLatestUpdatesInnerActor, data) = next_received!(actor.wrapper, data, actor.index)
on_error!(actor::CombineLatestUpdatesInnerActor, err) = error_received!(actor.wrapper, err, actor.index)
on_complete!(actor::CombineLatestUpdatesInnerActor)   = complete_received!(actor.wrapper, actor.index)

##

struct CombineLatestUpdatesActorWrapper{S, A, G, U}
    sources       :: S
    actor         :: A
    nsize         :: Int
    strategy      :: G # Push update strategy
    updates       :: U # Updates
    subscriptions :: Vector{Subscription}
end

function CombineLatestUpdatesActorWrapper(sources::S, actor::A, strategy::G) where { S, A, G } 
    updates       = getustorage(S)
    nsize         = length(sources)
    subscriptions = fill!(Vector{Subscription}(undef, nsize), noopSubscription)
    return CombineLatestUpdatesActorWrapper(sources, actor, nsize, strategy, updates, subscriptions)
end

push_update!(wrapper::CombineLatestUpdatesActorWrapper) = push_update!(wrapper.nsize, wrapper.updates, wrapper.strategy)

dispose(wrapper::CombineLatestUpdatesActorWrapper) = begin fill_cstatus!(wrapper.updates, true); foreach(s -> unsubscribe!(s), wrapper.subscriptions) end

function next_received!(wrapper::CombineLatestUpdatesActorWrapper, data, index::Int)
    vstatus!(wrapper.updates, index, true)
    ustatus!(wrapper.updates, index, true)
    if all_vstatus(wrapper.updates) && !all_cstatus(wrapper.updates)
        push_update!(wrapper)
        next!(wrapper.actor, wrapper.sources)
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

struct CombineLatestUpdatesObservable{S, G} <: Subscribable{S}
    sources  :: S
    strategy :: G
end

function on_subscribe!(observable::CombineLatestUpdatesObservable, actor)
    wrapper = CombineLatestUpdatesActorWrapper(observable.sources, actor, observable.strategy)

    __combine_latest_updates_unrolled_fill_subscriptions!(observable.sources, wrapper)

    if all_cstatus(wrapper.updates)
        dispose(wrapper)
    end

    return CombineLatestUpdatesSubscription(wrapper)
end

@unroll function __combine_latest_updates_unrolled_fill_subscriptions!(sources, wrapper::W) where { W <: CombineLatestUpdatesActorWrapper }
    subscriptions = wrapper.subscriptions
    updates       = wrapper.updates
    @unroll for index in 1:length(sources)
        @inbounds source = sources[index]
        @inbounds subscriptions[index] = subscribe!(source, CombineLatestUpdatesInnerActor{W}(index, wrapper))
        if cstatus(updates, index) && !vstatus(updates, index)
            dispose(wrapper)
            return
        end
    end
end

##

struct CombineLatestUpdatesSubscription{W} <: Subscription
    wrapper :: W
end

function on_unsubscribe!(subscription::CombineLatestUpdatesSubscription)
    dispose(subscription.wrapper)
    return nothing
end

Base.show(io::IO, ::CombineLatestUpdatesObservable{D}) where D  = print(io, "CombineLatestUpdatesObservable($D)")
Base.show(io::IO, ::CombineLatestUpdatesSubscription)           = print(io, "CombineLatestUpdatesSubscription()")

##
