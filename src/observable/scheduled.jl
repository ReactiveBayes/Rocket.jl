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

getscheduler(observable::ScheduledSource) = observable.scheduler

function on_subscribe!(source::ScheduledSource{L}, actor::A, scheduler::H) where { L, A, H }
    return subscribe!(source.source, ScheduledActor{L, H, A}(scheduler, actor))
end

Base.show(io::IO, ::ScheduledSource{L, H}) where { L, H } = print(io, "ScheduledSource($L, $H)")
Base.show(io::IO, ::ScheduledActor{H})     where { H }    = print(io, "ScheduledActor($H)")

scheduled(source::S, scheduler::H) where { S, H } = as_scheduled(eltype(S), source, scheduler)

as_scheduled(::Type{L}, source::S, scheduler::H)          where { L, H, S } = ScheduledSource{L, H, S}(scheduler, source)
as_scheduled(::Type{L}, source, scheduler::AsapScheduler) where L           = source
