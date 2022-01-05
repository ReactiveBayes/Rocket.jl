export AbstractSchedulerFactory, create_scheduler, getscheduler

"""
    getscheduler(any)

Returns an associated scheduler object.
"""
function getscheduler end

abstract type AbstractSchedulerFactory end

function create_scheduler end

subscribe!(factory::AbstractSchedulerFactory, subscribable, actor) = subscribe!(create_scheduler(eltype(subscribable), factory), subscribable, actor)
unsubscribe!(factory::AbstractSchedulerFactory, subscription)      = unsubscribe!(create_scheduler(eltype(subscribable), factory), subscription)