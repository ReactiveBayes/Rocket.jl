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

struct CombineLatestInnerActor{L, W, I} <: Actor{L}
    wrapper :: W
end

Base.show(io::IO, inner::CombineLatestInnerActor{L, W, I}) where { L, W, I } = print(io, "CombineLatestInnerActor($L, $I)")

on_next!(actor::CombineLatestInnerActor{L, W, I}, data::L) where { L, W, I } = next_received!(actor.wrapper, data, Val{I}())
on_error!(actor::CombineLatestInnerActor{L, W, I}, err)    where { L, W, I } = error_received!(actor.wrapper, err, Val{I}())
on_complete!(actor::CombineLatestInnerActor{L, W, I})      where { L, W, I } = complete_received!(actor.wrapper, Val{I}())

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

function next_received!(wrapper::CombineLatestActorWrapper, data, index::Val{I}) where I
    setstorage!(wrapper.storage, data, index)
    vstatus!(wrapper.updates, I, true)
    ustatus!(wrapper.updates, I, true)
    if all_vstatus(wrapper.updates) && !all_cstatus(wrapper.updates)
        push_update!(wrapper)
        next!(wrapper.actor, snapshot(wrapper.storage))
    end
end

function error_received!(wrapper::CombineLatestActorWrapper, err, index::Val{I}) where I
    if !(cstatus(wrapper.updates, I))
        dispose(wrapper)
        error!(wrapper.actor, err)
    end
end

function complete_received!(wrapper::CombineLatestActorWrapper, ::Val{I}) where I
    if !all_cstatus(wrapper.updates)
        cstatus!(wrapper.updates, I, true)
        if ustatus(wrapper.updates, I)
            vstatus!(wrapper.updates, I, true)
        end
        if all_cstatus(wrapper.updates) || (!vstatus(wrapper.updates, I))
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
    W       = typeof(wrapper)

    for (index, source) in enumerate(observable.sources)
        @inbounds wrapper.subscriptions[index] = subscribe!(source, CombineLatestInnerActor{eltype(source), W, index}(wrapper))
        if cstatus(wrapper.updates, index) && !vstatus(wrapper.updates, index)
            dispose(wrapper)
            break
        end
    end

    if all_cstatus(wrapper.updates)
        dispose(wrapper)
    end

    return CombineLatestSubscription(wrapper)
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
