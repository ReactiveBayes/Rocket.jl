export scheduled

# TODO: documentation

import Base: show

struct ScheduledActor{H, A}
    scheduler :: H
    actor     :: A
end

getscheduler(actor::ScheduledActor) = actor.scheduler

on_next!(actor::ScheduledActor, data) = next!(getscheduler(actor), actor.actor, data)
on_error!(actor::ScheduledActor, err) = error!(getscheduler(actor), actor.actor, err)
on_complete!(actor::ScheduledActor)   = complete!(getscheduler(actor), actor.actor)

struct ScheduledSource{L, H, S} <: Subscribable{L}
    scheduler :: H
    source    :: S
end

getscheduler(observable::ScheduledSource) = getscheduler(observable, observable.scheduler)

getscheduler(observable::ScheduledSource, scheduler)                           = scheduler
getscheduler(observable::ScheduledSource, scheduler::AbstractSchedulerFactory) = create_scheduler(eltype(observable.source), scheduler)

struct ScheduledSubscription{H, S} <: Subscription 
    scheduler    :: H
    subscription :: S
end

getscheduler(subscription::ScheduledSubscription) = subscription.scheduler

function subscribe!(source::ScheduledSource, actor)
    scheduler    = getscheduler(source)
    subscription = subscribe!(scheduler, source.source, ScheduledActor(scheduler, actor))
    return ScheduledSubscription(scheduler, subscription)
end

function subscribe!(source::ScheduledSource, fn::F) where { F <: Function }
    return subscribe!(source, FunctionActor{F}(fn))
end

function unsubscribe!(subscription::ScheduledSubscription)
    return unsubscribe!(getscheduler(subscription), subscription.subscription)
end

Base.show(io::IO, ::ScheduledSource{L, H})    where { L, H } = print(io, "ScheduledSource($L, $H)")
Base.show(io::IO, ::ScheduledSubscription{H}) where { H }    = print(io, "ScheduledSubscription($H)")
Base.show(io::IO, ::ScheduledActor{H})        where { H }    = print(io, "ScheduledActor($H)")

scheduled(source::S, scheduler::H) where { S, H } = as_scheduled(eltype(S), source, scheduler)

as_scheduled(::Type{L}, source::S, scheduler::H)           where { L, H, S } = ScheduledSource{L, H, S}(scheduler, source)
as_scheduled(::Type{L}, source, scheduler::AsapScheduler)  where { L       } = source
