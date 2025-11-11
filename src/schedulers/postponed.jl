export PostponeScheduler

import DataStructures: Queue, enqueue!, dequeue!
import Base: show, similar, wait

abstract type AbstractPostponedAction end

##

struct PostponeScheduler <: AbstractScheduler
    postponed_actions::Queue{AbstractPostponedAction}

    PostponeScheduler() = new(Queue{AbstractPostponedAction}())
end

Base.show(io::IO, ::PostponeScheduler) = print(io, "PostponeScheduler()")
Base.similar(::PostponeScheduler) = PostponeScheduler()

##

mutable struct PostponedSubscriptionProps
    is_subscribed::Bool
    is_unsubscribed::Bool
    subscription::Teardown

    PostponedSubscriptionProps() = new(false, false, voidTeardown)
end

## 

struct PostponedSubscriptionAction <: AbstractPostponedAction
    scheduler::PostponeScheduler
    source::Any
    actor::Any
    props::PostponedSubscriptionProps
end

function release!(action::PostponedSubscriptionAction)
    if !action.props.is_unsubscribed && !action.props.is_subscribed
        action.props.subscription =
            on_subscribe!(action.source, action.actor, action.scheduler)
        action.props.is_subscribed = true
    end
end

##

struct PostponedUnsubscriptionAction <: AbstractPostponedAction
    props::PostponedSubscriptionProps
end

function release!(action::PostponedUnsubscriptionAction)
    if !action.props.is_unsubscribed && action.props.is_subscribed
        unsubscribe!(action.props.subscription)
        action.props.is_unsubscribed = true
    end
end

##

struct PostponedNextAction <: AbstractPostponedAction
    actor::Any
    data::Any
end

release!(action::PostponedNextAction) = next!(action.actor, action.data)

##

struct PostponedErrorAction <: AbstractPostponedAction
    actor::Any
    error::Any
end

release!(action::PostponedErrorAction) = error!(action.actor, action.error)

##

struct PostponedCompleteAction <: AbstractPostponedAction
    actor::Any
end

release!(action::PostponedCompleteAction) = complete!(action.actor)

##

function release!(scheduler::PostponeScheduler)
    index = 1
    n = length(getactions(scheduler))
    while index <= n
        action = dequeue!(getactions(scheduler))
        release!(action)
        index += 1
    end
end

function Base.wait(scheduler::PostponeScheduler)
    while length(getactions(scheduler)) !== 0
        release!(scheduler)
    end
end

makeinstance(::Type, scheduler::PostponeScheduler) = scheduler

instancetype(::Type, ::Type{<: PostponeScheduler}) = PostponeScheduler

getactions(scheduler::PostponeScheduler) = scheduler.postponed_actions

scheduled_next!(actor, data, scheduler::PostponeScheduler) =
    enqueue!(getactions(scheduler), PostponedNextAction(actor, data))
scheduled_error!(actor, error, scheduler::PostponeScheduler) =
    enqueue!(getactions(scheduler), PostponedErrorAction(actor, error))
scheduled_complete!(actor, scheduler::PostponeScheduler) =
    enqueue!(getactions(scheduler), PostponedCompleteAction(actor))

function scheduled_subscription!(source, actor, scheduler::PostponeScheduler)
    postponed_subscription_props = PostponedSubscriptionProps()
    enqueue!(
        getactions(scheduler),
        PostponedSubscriptionAction(scheduler, source, actor, postponed_subscription_props),
    )
    return PostponedSubscription(scheduler, postponed_subscription_props)
end

struct PostponedSubscription <: Teardown
    scheduler::PostponeScheduler
    props::PostponedSubscriptionProps
end

as_teardown(::Type{<: PostponedSubscription}) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::PostponedSubscription)
    enqueue!(
        getactions(subscription.scheduler),
        PostponedUnsubscriptionAction(subscription.props),
    )
    return nothing
end
