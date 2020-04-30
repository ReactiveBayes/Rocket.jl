
"""
    AsyncScheduler

`AsyncScheduler` executes scheduled actions asynchronously

See also: [`getscheduler`](@ref), [`scheduled_subscription!`](@ref), [`scheduled_next!`](@ref), [`scheduled_error!`](@ref), [`scheduled_complete!`](@ref)
"""
struct AsyncScheduler{Delay} end

function AsyncScheduler(delay::Int = 0)
    return AsyncScheduler{delay}()
end

mutable struct AsyncSchedulerInstance{Delay}
    isunsubscribed :: Bool
    subscription   :: Teardown
end

makescheduler(::Type, ::Type{AsyncScheduler{Delay}}) where Delay = AsyncSchedulerInstance{Delay}(false, VoidTeardown())

isunsubscribed(scheduler::AsyncSchedulerInstance) = scheduler.isunsubscribed
delay(::AsyncSchedulerInstance{Delay}) where Delay = if Delay > 0 sleep(Delay / MILLISECONDS_IN_SECOND) end

function dispose(scheduler::AsyncSchedulerInstance)
    if !isunsubscribed(scheduler)
        unsubscribe!(scheduler.subscription)
        scheduler.isunsubscribed = true
    end
end

macro schedule_async(expr)
    output = quote
        if !isunsubscribed(scheduler)
            @async begin
                delay(scheduler)
                if !isunsubscribed(scheduler)
                    $(expr)
                end
            end
        end
    end
    return esc(output)
end

function scheduled_next!(actor, value, scheduler::AsyncSchedulerInstance)
    @schedule_async on_next!(actor, value)
end

function scheduled_error!(actor, err, scheduler::AsyncSchedulerInstance)
    @schedule_async begin
        dispose(scheduler)
        on_error!(actor, err)
    end
end

function scheduled_complete!(actor, scheduler::AsyncSchedulerInstance)
    @schedule_async begin
        dispose(scheduler)
        on_error!(actor, err)
    end
end

struct AsyncSchedulerSubscription{ H <: AsyncSchedulerInstance } <: Teardown
    instance :: H
end

as_teardown(::Type{ <: AsyncSchedulerSubscription}) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::AsyncSchedulerSubscription)
    dispose(subscription.instance)
    return nothing
end

function scheduled_subscription!(source, actor, scheduler::AsyncSchedulerInstance)
    subscription = AsyncSchedulerSubscription(scheduler)
    @async begin
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
