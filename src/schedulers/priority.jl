export PriorityScheduler

import Base: show, similar

"""
    PriorityScheduler

`PriorityScheduler` accepts a list of priority categories and executes only those actions which priority match the current activated priority setting.
Other actions are stored in a buffer and postponed until their priority setting will be activated. It is possible to execute all postponed actions in the order of the original
priority categories list with the `release!` function. `release!` function does not reset current priority. `PriorityScheduler` works with observables that send a tuple of `priority` and data. First element of this tuple should 
represent priority symbol and second element should represent the actual data.

Note: This scheduler does **not** prioritize `error!` and `complete!` events. These are executed as soon as possible.
Note: This scheduler does **not** prioritize `subscribe!` and `unsubscribe!` methods. These are executed as soon as possible.

See also: [`Rocket.setpriority!`](@ref), [`Rocket.setnextpriority!`](@ref)
"""
mutable struct PriorityScheduler{N} <: AbstractScheduler 
    priorities :: NTuple{N, Symbol}
    cpriority  :: Symbol
    postponed  :: NTuple{N, PostponeScheduler}
end

PriorityScheduler(priorities::NTuple{N, Symbol}) where N = PriorityScheduler(priorities, first(priorities))

function PriorityScheduler(priorities::NTuple{N, Symbol}, cpriority::Symbol) where N
    @assert cpriority ∈ priorities "Unknown priority setting $(cpriority) during creation of `PriorityScheduler` with priorities $(priorities)"
    return PriorityScheduler(priorities, cpriority, ntuple(i -> PostponeScheduler(), N))
end

priorities(scheduler::PriorityScheduler) = scheduler.priorities

postponed(scheduler::PriorityScheduler)                   = scheduler.postponed
postponed(scheduler::PriorityScheduler, priority::Symbol) = scheduler.postponed[ findnext(==(priority), priorities(scheduler), 1) ]

ispriority(scheduler::PriorityScheduler, priority::Symbol) = scheduler.cpriority === priority

""" 
    setpriority!(scheduler::PriorityScheduler, priority::Symbol)

Sets current priority for `PriorityScheduler` to be equal to `priority` label. Releases all postponed actions for this priority label.

See also: [`PriorityScheduler`](@ref), [`Rocket.setnextpriority!`](@ref)
"""
function setpriority!(scheduler::PriorityScheduler, priority::Symbol)
    @assert priority ∈ priorities(scheduler) "Unknown priority setting $(priority) for scheduler $(scheduler)"
    scheduler.cpriority = priority
    release!(postponed(scheduler, priority))
end

"""
    setnextpriority!(scheduler::PriorityScheduler)

Sets current priority label to be equal to the next priority label after currently activated (in a circular manner).

See also: [`PriorityScheduler`](@ref), [`Rocket.setpriority!`](@ref)
"""
function setnextpriority!(scheduler::PriorityScheduler)
    cpindex = findnext(==(scheduler.cpriority), priorities(scheduler), 1) # current priority index
    nextindex = cpindex + 1
    if nextindex > length(priorities(scheduler))
        nextindex = 1
    end
    setpriority!(scheduler, nextindex)
end

function release!(scheduler::PriorityScheduler)
    foreach(release!, postponed(scheduler))
end

function Base.show(io::IO, scheduler::PriorityScheduler) 
    println(io, "PriorityScheduler()")
    println(io, "  Priorities:        ", scheduler.priorities)
    println(io, "  Current priority:  ", scheduler.cpriority)
    println(io, "  Postponed actions: ", map(length, scheduler.postponed))
end

Base.similar(scheduler::PriorityScheduler{N}) where N = PriorityScheduler(scheduler.priorities, first(scheduler.priorities), ntuple(i -> PostponeScheduler(), N))

makeinstance(::Type, scheduler::PriorityScheduler) = scheduler

instancetype(::Type, ::Type{<:PriorityScheduler{N}}) where N = PriorityScheduler{N}

scheduled_subscription!(source, actor, instance::PriorityScheduler) = on_subscribe!(source, actor, instance)

scheduled_next!(actor, value, ::PriorityScheduler) = error("`PriorityScheduler` only accepts events in the form of the tuple (priority, data), but the value = $(value) has been send for the actor = $(actor).")

function scheduled_next!(actor, value::Tuple{Symbol, D}, scheduler::PriorityScheduler) where { D } 
    priority = value[1]
    @assert priority ∈ priorities(scheduler) "Unknown priority setting $(priority) for scheduler $(scheduler)"
    if ispriority(scheduler, priority)
        on_next!(actor, value)
    else
        scheduled_next!(actor, value, postponed(scheduler, priority))
    end
end

scheduled_error!(actor, err, ::PriorityScheduler)  = on_error!(actor, err)

function scheduled_complete!(actor, scheduler::PriorityScheduler) 
    # We would like to receive all postponed updates before sending completion event
    release!(scheduler)
    on_complete!(actor)
end
