
"""
    AbstractScheduler

Abstract supertype for all schedulers. A scheduler controls how and when an observable
delivers its actions: the initial subscription and each `next`, `error`, and `complete`
event. The default scheduler for almost all observables is [`AsapScheduler`](@ref), which
runs every action as soon as possible.

See also: [`getscheduler`](@ref), [`scheduled_subscription!`](@ref), [`scheduled_next!`](@ref), [`scheduled_error!`](@ref), [`scheduled_complete!`](@ref)
"""
abstract type AbstractScheduler end

"""
    getscheduler(scheduler)

Returns the scheduler instance associated with the given object. Most schedulers simply
return themselves.

See also: [`AbstractScheduler`](@ref)
"""
function getscheduler end

"""
    scheduled_subscription!(source, actor, instance)

Performs the subscription of `actor` to `source` according to the scheduler `instance`.
This is the entry point that a scheduler uses to control when and how a subscription happens.

See also: [`getscheduler`](@ref), [`scheduled_next!`](@ref), [`scheduled_error!`](@ref), [`scheduled_complete!`](@ref)
"""
function scheduled_subscription! end

"""
    scheduled_next!(actor, value, instance)

Delivers a `next` event with the given `value` to `actor` according to the scheduler `instance`.

See also: [`getscheduler`](@ref), [`scheduled_subscription!`](@ref), [`scheduled_error!`](@ref), [`scheduled_complete!`](@ref)
"""
function scheduled_next! end

"""
    scheduled_error!(actor, err, instance)

Delivers an `error` event with the given `err` to `actor` according to the scheduler `instance`.

See also: [`getscheduler`](@ref), [`scheduled_subscription!`](@ref), [`scheduled_next!`](@ref), [`scheduled_complete!`](@ref)
"""
function scheduled_error! end

"""
    scheduled_complete!(actor, instance)

Delivers a `complete` event to `actor` according to the scheduler `instance`.

See also: [`getscheduler`](@ref), [`scheduled_subscription!`](@ref), [`scheduled_next!`](@ref), [`scheduled_error!`](@ref)
"""
function scheduled_complete! end

"""
    makeinstance(::Type{L}, scheduler)

Creates a per-subscription scheduler instance for the data type `L`. Stateless schedulers
usually return themselves, while stateful ones return a fresh instance for each subscription.

See also: [`instancetype`](@ref), [`getscheduler`](@ref)
"""
function makeinstance end

"""
    instancetype(::Type{L}, ::Type{S})

Returns the type of the scheduler instance produced by [`makeinstance`](@ref) for the data
type `L` and the scheduler type `S`.

See also: [`makeinstance`](@ref), [`getscheduler`](@ref)
"""
function instancetype end
