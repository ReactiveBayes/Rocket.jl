export ScheduledSubscription

import Base: show

"""
    ScheduledSubscription{H, S}

`ScheduledSubscription` schedules unsubscription on a specified `scheduler`.

See also: [`scheduled`](@ref), [`Subscription`](@ref), [`unsubscribe!`](@ref), [`getscheduler`](@ref)
"""
struct ScheduledSubscription{H, S} <: Subscription 
    scheduler    :: H
    subscription :: S
end

Base.show(io::IO, ::ScheduledSubscription{H}) where { H }    = print(io, "ScheduledSubscription($H)")

getscheduler(subscription::ScheduledSubscription) = subscription.scheduler

on_unsubscribe!(subscription::ScheduledSubscription) = unsubscribe!(getscheduler(subscription), subscription.subscription)
