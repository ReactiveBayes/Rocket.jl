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

struct CombineLatestUpdatesInnerActor{L, W} <: Actor{L}
    index   :: Int
    wrapper :: W
end

Base.show(io::IO, ::CombineLatestUpdatesInnerActor{L, W}) where { L, W } = print(io, "CombineLatestUpdatesInnerActor($L, $I)")

on_next!(actor::CombineLatestUpdatesInnerActor{L, W}, data::L) where { L, W } = next_received!(actor.wrapper, data, actor.index)
on_error!(actor::CombineLatestUpdatesInnerActor{L, W}, err)    where { L, W } = error_received!(actor.wrapper, err, actor.index)
on_complete!(actor::CombineLatestUpdatesInnerActor{L, W})      where { L, W } = complete_received!(actor.wrapper, actor.index)

##

struct CombineLatestUpdatesActorWrapper{S, A, G}
    sources :: S
    actor   :: A

    nsize    :: Int
    strategy :: G           # Push update strategy
    cstatus  :: BitArray{1} # Completion status
    vstatus  :: BitArray{1} # Values status
    ustatus  :: BitArray{1} # Updates status

    subscriptions :: Vector{Teardown}

    CombineLatestUpdatesActorWrapper{S, A, G}(sources::S, actor::A, strategy::G) where { S, A, G } = begin
        nsize   = length(sources)
        cstatus = falses(nsize)
        vstatus = falses(nsize)
        ustatus = falses(nsize)
        subscriptions = fill!(Vector{Teardown}(undef, nsize), voidTeardown)
        return new(sources, actor, nsize, strategy, cstatus, vstatus, ustatus, subscriptions)
    end
end

push_update!(wrapper::CombineLatestUpdatesActorWrapper) = push_update!(wrapper.nsize, wrapper.vstatus, wrapper.cstatus, wrapper.strategy)

cstatus(wrapper::CombineLatestUpdatesActorWrapper, index) = @inbounds wrapper.cstatus[index]
vstatus(wrapper::CombineLatestUpdatesActorWrapper, index) = @inbounds wrapper.vstatus[index]
ustatus(wrapper::CombineLatestUpdatesActorWrapper, index) = @inbounds wrapper.ustatus[index]

dispose(wrapper::CombineLatestUpdatesActorWrapper) = begin fill!(wrapper.cstatus, true); foreach(s -> unsubscribe!(s), wrapper.subscriptions) end

function next_received!(wrapper::CombineLatestUpdatesActorWrapper, data, index::Int)
    @inbounds wrapper.vstatus[index] = true
    @inbounds wrapper.ustatus[index] = true
    if all(wrapper.vstatus) && !all(wrapper.cstatus)
        push_update!(wrapper)
        next!(wrapper.actor, wrapper.sources)
    end
end

function error_received!(wrapper::CombineLatestUpdatesActorWrapper, err, index)
    if !(@inbounds wrapper.cstatus[index])
        dispose(wrapper)
        error!(wrapper.actor, err)
    end
end

function complete_received!(wrapper::CombineLatestUpdatesActorWrapper, index::Int)
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

struct CombineLatestUpdatesObservable{S, G} <: Subscribable{S}
    sources  :: S
    strategy :: G
end

function on_subscribe!(observable::CombineLatestUpdatesObservable{S, G}, actor::A) where { S, G, A }
    wrapper = CombineLatestUpdatesActorWrapper{S, A, G}(observable.sources, actor, observable.strategy)

    for (index, source) in enumerate(observable.sources)
        @inbounds wrapper.subscriptions[index] = subscribe!(source, CombineLatestUpdatesInnerActor{eltype(source), typeof(wrapper)}(index, wrapper))
        if cstatus(wrapper, index) === true && vstatus(wrapper, index) === false
            dispose(wrapper)
            break
        end
    end

    if all(wrapper.cstatus)
        dispose(wrapper)
    end

    return CombineLatestUpdatesSubscription(wrapper)
end

##

struct CombineLatestUpdatesSubscription{W} <: Teardown
    wrapper :: W
end

as_teardown(::Type{ <: CombineLatestUpdatesSubscription }) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::CombineLatestUpdatesSubscription)
    dispose(subscription.wrapper)
    return nothing
end

Base.show(io::IO, ::CombineLatestUpdatesObservable{D}) where D  = print(io, "CombineLatestUpdatesObservable($D)")
Base.show(io::IO, ::CombineLatestUpdatesSubscription)           = print(io, "CombineLatestUpdatesSubscription()")

##
