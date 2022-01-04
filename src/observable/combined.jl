export combineLatest

import Base: show

"""
    combineLatest(sources...; strategy = PushEach())
    combineLatest(sources::S, strategy::G = PushEach()) where { S <: Tuple, U }

Combines multiple Observables to create an Observable whose values are calculated from the latest values of each of its input Observables.
Accept optinal update strategy object.

# Arguments
- `sources`: input sources
- `strategy`: optional update strategy for batching new values together

# Examples
```jldoctest
using Rocket

latest = combineLatest(of(1), from(2:5))

subscribe!(latest, logger())
;

# output

[LogActor] Data: (1, 2)
[LogActor] Data: (1, 3)
[LogActor] Data: (1, 4)
[LogActor] Data: (1, 5)
[LogActor] Completed
```

```
using Rocket

latest = combineLatest(of(1) |> async(0), from(2:5) |> async(0), strategy = PushNew())

subscribe!(latest, logger())
;

# output

[LogActor] Data: (1, 2)
[LogActor] Completed
```

See also: [`Subscribable`](@ref), [`subscribe!`](@ref), [`PushEach`](@ref), [`PushEachBut`](@ref), [`PushNew`](@ref), [`PushNewBut`](@ref), [`PushStrategy`](@ref)
"""
function combineLatest end

combineLatest(; strategy = PushEach())                                       = error("combineLatest operator expects at least one inner observable on input")
combineLatest(args...; strategy = PushEach())                                = combineLatest(args, strategy)
combineLatest(sources::S, strategy::G = PushEach()) where { S <: Tuple, G }  = CombineLatestObservable{combined_eltype(sources), S, G}(sources, strategy)
combineLatest(sources::V, strategy::G = PushEach()) where { V <: Vector, G } = CombineLatestObservable{combined_eltype(sources), V, G}(sources, strategy)

##

struct CombineLatestInnerActor{W}
    index   :: Int
    wrapper :: W
end

Base.show(io::IO, ::CombineLatestInnerActor) = print(io, "CombineLatestInnerActor()")

on_next!(actor::CombineLatestInnerActor, data) = next_received!(actor.wrapper, data, actor.index)
on_error!(actor::CombineLatestInnerActor, err) = error_received!(actor.wrapper, err, actor.index)
on_complete!(actor::CombineLatestInnerActor)   = complete_received!(actor.wrapper, actor.index)

##

struct CombineLatestActorWrapper{S, A, G, U}
    storage       :: S
    actor         :: A
    nsize         :: Int
    strategy      :: G
    updates       :: U
    subscriptions :: Vector{Subscription}
end

function CombineLatestActorWrapper(::Type{T}, actor::A, strategy::G) where { T, A, G } 
    storage       = getmstorage(T)
    updates       = getustorage(T)
    nsize         = length(storage)
    subscriptions = fill!(Vector{Subscription}(undef, nsize), noopSubscription)
    return CombineLatestActorWrapper(storage, actor, nsize, strategy, updates, subscriptions)
end

push_update!(wrapper::CombineLatestActorWrapper) = push_update!(wrapper.nsize, wrapper.updates, wrapper.strategy)

dispose(wrapper::CombineLatestActorWrapper) = begin fill_cstatus!(wrapper.updates, true); foreach(s -> unsubscribe!(s), wrapper.subscriptions) end

function next_received!(wrapper::CombineLatestActorWrapper, data, index::Int)
    setstorage!(wrapper.storage, data, index)
    vstatus!(wrapper.updates, index, true)
    ustatus!(wrapper.updates, index, true)
    if all_vstatus(wrapper.updates) && !all_cstatus(wrapper.updates)
        push_update!(wrapper)
        on_next!(wrapper.actor, snapshot(wrapper.storage))
    end
end

function error_received!(wrapper::CombineLatestActorWrapper, err, index::Int)
    if !(cstatus(wrapper.updates, index))
        dispose(wrapper)
        on_error!(wrapper.actor, err)
    end
end

function complete_received!(wrapper::CombineLatestActorWrapper, index::Int)
    if !all_cstatus(wrapper.updates)
        cstatus!(wrapper.updates, index, true)
        if ustatus(wrapper.updates, index)
            vstatus!(wrapper.updates, index, true)
        end
        if all_cstatus(wrapper.updates) || (!vstatus(wrapper.updates, index))
            dispose(wrapper)
            on_complete!(wrapper.actor)
        end
    end
end

##

struct CombineLatestObservable{T, S, G} <: Subscribable{T}
    sources  :: S
    strategy :: G
end

function on_subscribe!(observable::CombineLatestObservable{T}, actor) where T
    wrapper = CombineLatestActorWrapper(T, actor, observable.strategy)

    __combine_latest_unrolled_fill_subscriptions!(observable.sources, wrapper)

    if all_cstatus(wrapper.updates)
        dispose(wrapper)
    end

    return CombineLatestSubscription(wrapper)
end

@unroll function __combine_latest_unrolled_fill_subscriptions!(sources, wrapper::W) where { W <: CombineLatestActorWrapper }
    subscriptions = wrapper.subscriptions
    updates = wrapper.updates
    @unroll for index in 1:length(sources)
        @inbounds source = sources[index]
        @inbounds subscriptions[index] = subscribe!(source, CombineLatestInnerActor{W}(index, wrapper))
        if cstatus(updates, index) && !vstatus(updates, index)
            dispose(wrapper)
            return
        end
    end
end

##

struct CombineLatestSubscription{W} <: Subscription
    wrapper :: W
end

function on_unsubscribe!(subscription::CombineLatestSubscription)
    dispose(subscription.wrapper)
    return nothing
end

Base.show(io::IO, ::CombineLatestObservable{D}) where D  = print(io, "CombineLatestObservable($D)")
Base.show(io::IO, ::CombineLatestSubscription)           = print(io, "CombineLatestSubscription()")

##
