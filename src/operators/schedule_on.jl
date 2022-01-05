export schedule_on

import Base: show

# TODO : Untested and undocumented

schedule_on(scheduler::H) where { H } = ScheduleOnOperator{H}(scheduler)

struct ScheduleOnOperator{H} <: Operator
    scheduler :: H
end

operator_eltype(::ScheduleOnOperator, ::Type{L}) where L = L

function on_call!(::Type{L}, ::Type{L}, operator::ScheduleOnOperator{H}, source::S) where { L, H, S }
    return scheduled(source, operator.scheduler)
end

Base.show(io::IO, ::ScheduleOnOperator{H}) where H = print(io, "ScheduleOnOperator($H)")
