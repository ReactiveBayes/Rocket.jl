export LastCollectedObservable, on_subscribe!
export LastCollectedObservableWrapper
export LastCollectedActor, on_next!, on_error!, on_complete!
export collectLast

# TODO: WIP fix if some source emits only complete

struct LastCollectedObservable{D} <: Subscribable{Vector{D}}
    sources :: Vector{Any}
end

function on_subscribe!(observable::LastCollectedObservable{D}, actor) where D
    wrapper = LastCollectedObservableWrapper{D}(observable.sources, actor)
    return LastCollectedSubscription(wrapper)
end

struct LastCollectedSubscription
    wrapper
end

as_teardown(::Type{<:LastCollectedSubscription}) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::LastCollectedSubscription)
    _dispose_inner_subscriptions(subscription.wrapper)
    return nothing
end

## Creation operators ##

collectLast(::Type{D}, sources) where D = LastCollectedObservable{D}(sources)

## Wrapper ##

mutable struct LastCollectedObservableWrapper{D}
    values               :: Vector{D}
    size                 :: Int
    completed_count      :: Int
    inner_subscriptions  :: Vector{Teardown}
    actor

    LastCollectedObservableWrapper{D}(sources::Vector{Any}, actor) where D = begin
        size            = length(sources)
        values          = Vector{D}(undef, size)
        completed_count = 0
        inner_subscriptions = Vector{Teardown}(undef, size)

        wrapper = new(values, size, completed_count, inner_subscriptions, actor)

        is_error = false

        try
            for index in 1:size
                if !is_error
                    source = sources[index]
                    collection_actor = LastCollectedActor{D}(index, wrapper)
                    subscription = subscribe!(source, collection_actor)
                    inner_subscriptions[index] = subscription
                end
            end
        catch err
            is_error = true
            _dispose_inner_subscriptions(wrapper)
        end

        return wrapper
    end
end

function _check_completed(wrapper::LastCollectedObservableWrapper)
    if wrapper.completed_count == wrapper.size
        next!(wrapper.actor, wrapper.values)
        complete!(wrapper.actor)
    end
end

function _dispose_inner_subscriptions(wrapper::LastCollectedObservableWrapper)
    for index in 1:wrapper.size
        if isdefined(wrapper.inner_subscriptions, index)
            unsubscribe!(wrapper.inner_subscriptions[index])
        end
    end
end

## Actors ##

mutable struct LastCollectedActor{D} <: Actor{D}
    index      :: Int
    wrapper    :: LastCollectedObservableWrapper{D}
    last_value :: Union{Nothing, D}

    LastCollectedActor{D}(index::Int, wrapper::LastCollectedObservableWrapper{D}) where D = new(index, wrapper, nothing)
end

function on_next!(actor::LastCollectedActor{D}, data::D) where D
    actor.last_value = data
end

function on_error!(actor::LastCollectedActor, err)
    error!(actor.wrapper.actor, err)
    _dispose_inner_subscriptions(actor.wrapper)
end

function on_complete!(actor::LastCollectedActor)
    actor.wrapper.values[actor.index] = actor.last_value
    actor.wrapper.completed_count += 1
    _check_completed(actor.wrapper)
end
