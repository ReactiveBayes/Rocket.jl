export scheduled

# TODO: documentation

import Base: show

struct ScheduledActor{L,H,A} <: Actor{L}
    scheduler::H
    actor::A
end

on_next!(actor::ScheduledActor{L}, data::L) where {L} =
    next!(actor.actor, data, actor.scheduler)
on_error!(actor::ScheduledActor, err) = error!(actor.actor, err, actor.scheduler)
on_complete!(actor::ScheduledActor) = complete!(actor.actor, actor.scheduler)

@subscribable struct ScheduledSource{L,H<:AbstractScheduler,S} <: ScheduledSubscribable{L}
    source::S
    scheduler::H
end

getscheduler(observable::ScheduledSource) = observable.scheduler

function on_subscribe!(source::ScheduledSource{L}, actor::A, scheduler::H) where {L,A,H}
    return subscribe!(source.source, ScheduledActor{L,H,A}(scheduler, actor))
end

Base.show(io::IO, ::ScheduledSource{L,H}) where {L,H} = print(io, "ScheduledSource($L, $H)")
Base.show(io::IO, ::ScheduledActor{L,H}) where {L,H} = print(io, "ScheduledActor($L, $H)")

scheduled(source::S, scheduler::H) where {S,H<:AbstractScheduler} =
    as_scheduled(as_subscribable(S), source, scheduler)

as_scheduled(::InvalidSubscribableTrait, source, scheduler) =
    throw(InvalidSubscribableTraitUsageError(source))
as_scheduled(::SimpleSubscribableTrait{L}, source::S, scheduler::H) where {L,H,S} =
    ScheduledSource{L,H,S}(source, scheduler)
as_scheduled(::ScheduledSubscribableTrait{L}, source::S, scheduler::H) where {L,H,S} =
    ScheduledSource{L,H,S}(source, scheduler)

as_scheduled(::SimpleSubscribableTrait, source, scheduler::AsapScheduler) = source
as_scheduled(::ScheduledSubscribableTrait, source, scheduler::AsapScheduler) = source
