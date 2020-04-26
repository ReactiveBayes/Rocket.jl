
"""
    AsyncScheduler

`AsyncScheduler` executes scheduled actions asynchronously

See also: [`getscheduler`](@ref), [`scheduled_subscription!`](@ref), [`scheduled_next!`](@ref), [`scheduled_error!`](@ref), [`scheduled_complete!`](@ref)
"""
struct AsyncScheduler end

# TODO WIP

function scheduled_subscription!(source, actor, scheduler::AsyncScheduler)
    return on_subscribe!(source, actor, scheduler)
end

scheduled_next!(actor, value, ::AsyncScheduler) = @async begin on_next!(actor, value) end
scheduled_error!(actor, err, ::AsyncScheduler)  = @async begin on_error!(actor, err) end
scheduled_complete!(actor, ::AsyncScheduler)    = @async begin on_complete!(actor) end
