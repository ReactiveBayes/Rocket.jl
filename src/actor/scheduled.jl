export ScheduledActor

import Base: show

"""
    ScheduledActor{H, S}

`ScheduledActor` schedules `next!`, `error!` and `complete!` events on a specified `scheduler`.

See also: [`scheduled`](@ref), [`next!`](@ref), [`error!`](@ref), [`complete!`](@ref), [`getscheduler`](@ref)
"""
struct ScheduledActor{H, A}
    scheduler :: H
    actor     :: A
end

Base.show(io::IO, ::ScheduledActor{H}) where { H } = print(io, "ScheduledActor($H)")

getscheduler(actor::ScheduledActor) = actor.scheduler

on_next!(actor::ScheduledActor, data) = next!(getscheduler(actor), actor.actor, data)
on_error!(actor::ScheduledActor, err) = error!(getscheduler(actor), actor.actor, err)
on_complete!(actor::ScheduledActor)   = complete!(getscheduler(actor), actor.actor)