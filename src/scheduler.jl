export Scheduler

abstract type Scheduler end

"""
    getscheduler(subscribable)

Returns a scheduler object for `subscribable`.

See also: [`scheduled_subscription!`](@ref), [`scheduled_next!`](@ref), [`scheduled_error!`](@ref), [`scheduled_complete!`](@ref)
"""
function getscheduler end

"""
    makeinstance(::Type{ T }, scheduler) where T

Creates an instance of a `scheduler` to operate on data type `T`.

See also: [`getscheduler`](@ref), [`instancetype`](@ref)
"""
function makeinstance end

"""
    instancetype(::Type{T}, scheduler) where T

Returns an instance object type of `scheduler` based on data type `T`

See also: [`getscheduler`](@ref), [`makeinstance`](@ref)
"""
function instancetype end

# Default method for `Scheduler` is to call the `makeinstance` function
subscribe!(subscribable, actor, scheduler::Scheduler) = on_subscribe!(subscribable, actor, makeinstance(eltype(subscribable), scheduler))