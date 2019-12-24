export LatestCombined2Observable, on_subscribe!
export LatestCombined2Subscription, as_teardown, on_unsubscribe!
export LatestCombinedActor1, on_next!, on_error!, on_complete!
export LatestCombinedActor2, on_next!, on_error!, on_complete!
export combineLatest

# TODO It is better to use macro to create this structures and actors
# Consider to reimplement it in the future. For now implement just a two combined
struct LatestCombined2Observable{S1, D1, S2, D2} <: Subscribable{Tuple{D1, D2}}
    source1 :: S1
    source2 :: S2

    LatestCombined2Observable{S1, D1, S2, D2}(source1::S1, source2::S2) where S1 where S2 where D1 where D2 = new(source1, source2)
end

function on_subscribe!(observable::LatestCombined2Observable{S1, D1, S2, D2}, actor::A) where { A <: AbstractActor{Tuple{D1, D2}} } where S1 where S2 where D1 where D2
    wrapper = LatestCombinedObservable2ActorWrapper{D1, D2, A}(observable.source1, observable.source2, actor)
    return LatestCombined2Subscription(wrapper)
end

struct LatestCombined2Subscription <: Teardown
    wrapper
end

as_teardown(::Type{<:LatestCombined2Subscription}) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::LatestCombined2Subscription)
    _dispose_on_complete(subscription.wrapper)
    if isdefined(subscription.wrapper, :subscription)
        unsubscribe!(subscription.wrapper.subscription)
    end
    return nothing
end

### Creation operators ###

"""
    combineLatest(source1::S1, source2::S2) where S1 where S2

Combines multiple Observables to create an Observable whose values are calculated from the latest values of each of its input Observables.

See also: [`Subscribable`](@ref)
"""
combineLatest(source1::S1, source2::S2) where S1 where S2 = combineLatest(as_subscribable(S1), as_subscribable(S2), source1, source2)

combineLatest(::InvalidSubscribable, as_subscribable, source1, source2) = throw(InvalidSubscribableTraitUsageError(source1))
combineLatest(as_subscribable, ::InvalidSubscribable, source1, source2) = throw(InvalidSubscribableTraitUsageError(source2))

function combineLatest(::ValidSubscribable{D1}, ::ValidSubscribable{D2}, source1::S1, source2::S2) where S1 where S2 where D1 where D2
    return LatestCombined2Observable{S1, D1, S2, D2}(source1, source2)
end

function combineLatest(source1::SingleObservable{S1}, source2::SingleObservable{S2}) where S1 where S2
    return SingleObservable{Tuple{S1, S2}}((source1.value, source2.value))
end

### Specific Actors ###

macro MakeLatestCombinedActor(n)
    actor       = Symbol("LatestCombinedActor", n)
    on_next     = Symbol("next_", n, "!")
    on_error    = Symbol("error_", n, "!")
    on_complete = Symbol("complete_", n, "!")

    esc(quote
        struct ($actor){D, W} <: Actor{D}
            wrapper::W

            $actor{D, W}(wrapper::W) where D where W = new(wrapper)
        end

        on_next!(actor::($actor){D, W}, data::D) where D where W = $on_next(actor.wrapper, data)
        on_error!(actor::($actor), err)                          = $on_error(actor.wrapper, err)
        on_complete!(actor::($actor))                            = $on_complete(actor.wrapper)
    end)
end

@MakeLatestCombinedActor(1)
@MakeLatestCombinedActor(2)

### Base Actor wrappers ###
### TODO: Again it is better to write a macro for this kind of structures and pregenerate a lot of them

mutable struct LatestCombinedObservable2ActorWrapper{ D1, D2, A <: AbstractActor{Tuple{D1, D2}} }
    actor1 :: LatestCombinedActor1{D1}
    actor2 :: LatestCombinedActor2{D2}
    actor  :: A

    latest1 :: Union{D1, Nothing}
    latest2 :: Union{D2, Nothing}

    is_completed1 :: Bool
    is_completed2 :: Bool
    is_completed  :: Bool

    subject :: Subject{Tuple{D1, D2}}

    subscription1 :: Teardown
    subscription2 :: Teardown
    subscription  :: Teardown

    LatestCombinedObservable2ActorWrapper{D1, D2, A}(source1, source2, actor::A) where { A <: AbstractActor{Tuple{D1, D2}} } where D1 where D2 = begin
        subject      = Subject{Tuple{D1, D2}}()
        subscription = subscribe!(subject, actor)

        wrapper = new()

        actor1 = LatestCombinedActor1{ D1, LatestCombinedObservable2ActorWrapper{D1, D2, A} }(wrapper)
        actor2 = LatestCombinedActor2{ D2, LatestCombinedObservable2ActorWrapper{D1, D2, A} }(wrapper)

        wrapper.actor1 = actor1
        wrapper.actor2 = actor2
        wrapper.actor  = actor

        wrapper.latest1 = nothing
        wrapper.latest2 = nothing

        wrapper.is_completed1 = false
        wrapper.is_completed2 = false
        wrapper.is_completed  = false

        wrapper.subject       = subject
        wrapper.subscription  = subscription
        wrapper.subscription1 = subscribe!(source1, wrapper.actor1)
        wrapper.subscription2 = subscribe!(source2, wrapper.actor2)

        return wrapper
    end
end

### Emit logic for base combined actors ###

function next_1!(wrapper::LatestCombinedObservable2ActorWrapper{D1, D2, A}, data::D1) where { A <: AbstractActor{Tuple{D1, D2}} } where D1 where D2
    wrapper.latest1 = data
    next_check_and_emit!(wrapper)
end

function next_2!(wrapper::LatestCombinedObservable2ActorWrapper{D1, D2, A}, data::D2) where { A <: AbstractActor{Tuple{D1, D2}} } where D1 where D2
    wrapper.latest2 = data
    next_check_and_emit!(wrapper)
end

function next_check_and_emit!(wrapper::LatestCombinedObservable2ActorWrapper)
    if !wrapper.is_completed && (wrapper.latest1 != nothing && wrapper.latest2 != nothing)
        next!(wrapper.subject, (wrapper.latest1, wrapper.latest2))
        # TODO this is wrong but anyway
        if !wrapper.is_completed1
            wrapper.latest1 = nothing
        end
        if !wrapper.is_completed2
            wrapper.latest2 = nothing
        end
    end
end

function error_1!(wrapper::LatestCombinedObservable2ActorWrapper, err)
    error!(wrapper.subject, err)
    _dispose_on_complete(wrapper)
    if isdefined(wrapper, :subscription)
        unsubscribe!(wrapper.subscription)
    end
end

function error_2!(wrapper::LatestCombinedObservable2ActorWrapper, err)
    error!(wrapper.subject, err)
    _dispose_on_complete(wrapper)
    if isdefined(wrapper, :subscription)
        unsubscribe!(wrapper.subscription)
    end
end

function complete_1!(wrapper::LatestCombinedObservable2ActorWrapper)
    wrapper.is_completed1 = true
    if wrapper.latest1 == nothing
        wrapper.is_completed = true
    end
    _check_complete(wrapper)
end

function complete_2!(wrapper::LatestCombinedObservable2ActorWrapper)
    wrapper.is_completed2 = true
    if wrapper.latest2 == nothing
        wrapper.is_completed = true
    end
    _check_complete(wrapper)
end

function _check_complete(wrapper::LatestCombinedObservable2ActorWrapper)
    if wrapper.is_completed || (wrapper.is_completed1 && wrapper.is_completed2)
        wrapper.is_completed = true
        complete!(wrapper.subject)
        _dispose_on_complete(wrapper)
    end
end

function _dispose_on_complete(wrapper::LatestCombinedObservable2ActorWrapper)
    if isdefined(wrapper, :subscription1)
        unsubscribe!(wrapper.subscription1)
    end

    if isdefined(wrapper, :subscription2)
        unsubscribe!(wrapper.subscription2)
    end
end
