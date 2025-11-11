export schedule_on

import Base: show

# TODO : Untested and undocumented

schedule_on(scheduler::H) where {H<:AbstractScheduler} = ScheduleOnOperator{H}(scheduler)

struct ScheduleOnOperator{H<:AbstractScheduler} <: InferableOperator
    scheduler::H
end

operator_right(operator::ScheduleOnOperator, ::Type{L}) where {L} = L

function on_call!(
    ::Type{L},
    ::Type{L},
    operator::ScheduleOnOperator{H},
    source::S,
) where {L,H,S}
    return scheduled(source, operator.scheduler)
end

Base.show(io::IO, ::ScheduleOnOperator{H}) where {H} = print(io, "ScheduleOnOperator($H)")
