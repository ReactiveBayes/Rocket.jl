
# experimental

"""
    ThreadsScheduler

`ThreadsScheduler` executes scheduled actions in a different threads

See also: [`getscheduler`](@ref), [`scheduled_subscription!`](@ref), [`scheduled_next!`](@ref), [`scheduled_error!`](@ref), [`scheduled_complete!`](@ref)
"""
struct ThreadsScheduler end

mutable struct ThreadsSchedulerInstance
    isunsubscribed :: Bool
    subscription   :: Teardown
end

makescheduler(::Type, ::Type{ThreadsScheduler}) = ThreadsSchedulerInstance(false, VoidTeardown())

isunsubscribed(scheduler::ThreadsSchedulerInstance) = scheduler.isunsubscribed

function dispose(scheduler::ThreadsSchedulerInstance)
    if !isunsubscribed(scheduler)
        unsubscribe!(scheduler.subscription)
        scheduler.isunsubscribed = true
    end
end

macro schedule_onthread(expr)
    output = quote
        if !isunsubscribed(scheduler)
            Threads.@spawn begin
                if !isunsubscribed(scheduler)
                    $(expr)
                end
            end
        end
    end
    return esc(output)
end

function scheduled_next!(actor, value, scheduler::ThreadsSchedulerInstance)
    @schedule_onthread on_next!(actor, value)
end

function scheduled_error!(actor, err, scheduler::ThreadsSchedulerInstance)
    @schedule_onthread begin
        dispose(scheduler)
        on_error!(actor, err)
    end
end

function scheduled_complete!(actor, scheduler::ThreadsSchedulerInstance)
    @schedule_onthread begin
        dispose(scheduler)
        on_error!(actor, err)
    end
end

struct ThreadsSchedulerSubscription{ H <: ThreadsSchedulerInstance } <: Teardown
    instance :: H
end

as_teardown(::Type{ <: ThreadsSchedulerSubscription}) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::ThreadsSchedulerSubscription)
    dispose(subscription.instance)
    return nothing
end

function scheduled_subscription!(source, actor, scheduler::ThreadsSchedulerInstance)
    subscription = ThreadsSchedulerSubscription(scheduler)
    Threads.@spawn begin
        if !isunsubscribed(scheduler)
            tmp = on_subscribe!(source, actor, scheduler)
            if !isunsubscribed(scheduler)
                subscription.subscription = tmp
            else
                unsubscribe!(tmp)
            end
        end
    end
    return subscription
end
