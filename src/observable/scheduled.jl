export scheduled

import Base: show

"""
    ScheduledSource{H, S}

`ScheduledSource` schedules `subscribe!` on a specified `scheduler`.

See also: [`scheduled`](@ref), [`subscribe!`](@ref), [`getscheduler`](@ref)
"""
struct ScheduledSource{L, H, S} <: Subscribable{L}
    scheduler :: H
    source    :: S
end

getscheduler(observable::ScheduledSource) = observable.scheduler

function on_subscribe!(source::ScheduledSource, actor)
    return subscribe!(getscheduler(source), source.source, actor)
end

Base.show(io::IO, ::ScheduledSource{L, H}) where { L, H } = print(io, "ScheduledSource($L, $H)")

scheduled(source::S, scheduler::H) where { S, H } = as_scheduled(eltype(S), source, scheduler)

as_scheduled(::Type{L}, source::S, scheduler::H)           where { L, H, S } = ScheduledSource{L, H, S}(scheduler, source)
as_scheduled(::Type{L}, source, scheduler::AsapScheduler)  where { L       } = source
