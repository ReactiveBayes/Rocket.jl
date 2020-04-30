export schedule_on

import Base: show

# TODO : Untested and undocumented

schedule_on(scheduler::H) where H = ScheduleOnOperator{H}()

struct ScheduleOnOperator{H} <: InferableOperator end

operator_right(operator::ScheduleOnOperator, ::Type{L}) where L = L

function on_call!(::Type{L}, ::Type{L}, operator::ScheduleOnOperator{H}, source::S) where { L, H, S }
    return ScheduleOnSource{L, H, S}(source)
end

struct ScheduleOnActor{L, H, A} <: Actor{L}
    scheduler :: H
    actor     :: A
end

on_next!(actor::ScheduleOnActor{L}, data::L) where L = next!(actor.actor, data, actor.scheduler)
on_error!(actor::ScheduleOnActor, err)               = error!(actor.actor, err, actor.scheduler)
on_complete!(actor::ScheduleOnActor)                 = complete!(actor.actor, actor.scheduler)

struct ScheduleOnSource{L, H, S} <: ScheduledSubscribable{L}
    source :: S
end

getscheduler(::ScheduleOnSource{L, H, S}) where { L, H, S } = makescheduler(L, H)

function on_subscribe!(source::ScheduleOnSource{L}, actor::A, scheduler::H) where { L, A, H }
    return subscribe!(source.source, ScheduleOnActor{L, H, A}(scheduler, actor))
end

Base.show(io::IO, ::ScheduleOnOperator{H})  where H        = print(io, "ScheduleOnOperator($H)")
Base.show(io::IO, ::ScheduleOnSource{L, H}) where { L, H } = print(io, "ScheduleOnSource($L, $H)")
Base.show(io::IO, ::ScheduleOnActor{L, H})  where { L, H } = print(io, "ScheduleOnActor($L, $H)")
