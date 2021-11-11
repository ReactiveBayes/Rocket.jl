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
combineLatest(sources::S, strategy::G = PushEach()) where { S <: Tuple, G }  = CombineLatestObservable{combined_type(sources), S, G}(sources, strategy)
combineLatest(sources::V, strategy::G = PushEach()) where { V <: Vector, G } = CombineLatestObservable{combined_type(sources), V, G}(sources, strategy)

##

struct CombineLatestInnerActor{L, W} <: Actor{L}
    index   :: Int
    wrapper :: W
end

Base.show(io::IO, ::CombineLatestInnerActor{L, W}) where { L, W } = print(io, "CombineLatestInnerActor($L)")

on_next!(actor::CombineLatestInnerActor{L, W}, data::L) where { L, W } = next_received!(actor.wrapper, data, actor.index)
on_error!(actor::CombineLatestInnerActor{L, W}, err)    where { L, W } = error_received!(actor.wrapper, err, actor.index)
on_complete!(actor::CombineLatestInnerActor{L, W})      where { L, W } = complete_received!(actor.wrapper, actor.index)

##

struct CombineLatestActorWrapper{S, A, G, U}
    storage       :: S
    actor         :: A
    nsize         :: Int
    strategy      :: G
    updates       :: U
    subscriptions :: Vector{Teardown}
end

function CombineLatestActorWrapper(::Type{T}, actor::A, strategy::G) where { T, A, G } 
    storage       = getmstorage(T)
    updates       = getustorage(T)
    nsize         = length(storage)
    subscriptions = fill!(Vector{Teardown}(undef, nsize), voidTeardown)
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
        next!(wrapper.actor, snapshot(wrapper.storage))
    end
end

function error_received!(wrapper::CombineLatestActorWrapper, err, index::Int)
    if !(cstatus(wrapper.updates, index))
        dispose(wrapper)
        error!(wrapper.actor, err)
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
            complete!(wrapper.actor)
        end
    end
end

##

@subscribable struct CombineLatestObservable{T, S, G} <: Subscribable{T}
    sources  :: S
    strategy :: G
end

function on_subscribe!(observable::CombineLatestObservable{T, S, G}, actor::A) where { T, S, G, A }
    wrapper = CombineLatestActorWrapper(T, actor, observable.strategy)

    __combine_latest_unrolled_fill_subscriptions!(observable.sources, wrapper)

    if all_cstatus(wrapper.updates)
        dispose(wrapper)
    end

    return CombineLatestSubscription(wrapper)
end

Unrolled.@unroll function __combine_latest_unrolled_fill_subscriptions!(sources, wrapper::W) where { W <: CombineLatestActorWrapper }
    subscriptions = wrapper.subscriptions
    updates = wrapper.updates
    Unrolled.@unroll for index in 1:length(sources)
        @inbounds source = sources[index]
        @inbounds subscriptions[index] = subscribe!(source, CombineLatestInnerActor{eltype(source), W}(index, wrapper))
        if cstatus(updates, index) && !vstatus(updates, index)
            dispose(wrapper)
            return
        end
    end
end

##

struct CombineLatestSubscription{W} <: Teardown
    wrapper :: W
end

as_teardown(::Type{ <: CombineLatestSubscription }) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::CombineLatestSubscription)
    dispose(subscription.wrapper)
    return nothing
end

Base.show(io::IO, ::CombineLatestObservable{D}) where D  = print(io, "CombineLatestObservable($D)")
Base.show(io::IO, ::CombineLatestSubscription)           = print(io, "CombineLatestSubscription()")

##
