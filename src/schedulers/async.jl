

"""
    AsyncScheduler

`AsyncScheduler` executes scheduled actions asynchronously

See also: [`getscheduler`](@ref), [`scheduled_subscription!`](@ref), [`scheduled_next!`](@ref), [`scheduled_error!`](@ref), [`scheduled_complete!`](@ref)
"""
struct AsyncScheduler
    delay :: Int

    AsyncScheduler(delay::Int = 0) = new(delay)
end

mutable struct AsyncSchedulerInstance
    delay          :: Float64
    isunsubscribed :: Bool
    subscription   :: Teardown
end

makeinstance(::Type, scheduler::AsyncScheduler) = AsyncSchedulerInstance(scheduler.delay / MILLISECONDS_IN_SECOND, false, VoidTeardown())

instancetype(::Type, ::Type{<:AsyncScheduler}) = AsyncSchedulerInstance

isunsubscribed(instance::AsyncSchedulerInstance) = instance.isunsubscribed

function delay(instance::AsyncSchedulerInstance)
    if instance.delay >= 0.001
        sleep(instance.delay)
    end
end

function dispose(instance::AsyncSchedulerInstance)
    if !isunsubscribed(instance)
        unsubscribe!(instance.subscription)
        instance.isunsubscribed = true
    end
end

macro schedule_async(expr)
    output = quote
        if !isunsubscribed(instance)
            @async begin
                delay(instance)
                if !isunsubscribed(instance)
                    $(expr)
                end
            end
        end
    end
    return esc(output)
end

function scheduled_next!(actor, value, instance::AsyncSchedulerInstance)
    @schedule_async begin
        on_next!(actor, value)
    end
end

function scheduled_error!(actor, err, instance::AsyncSchedulerInstance)
    @schedule_async begin
        dispose(instance)
        on_error!(actor, err)
    end
end

function scheduled_complete!(actor, instance::AsyncSchedulerInstance)
    @schedule_async begin
        dispose(instance)
        on_complete!(actor)
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

function scheduled_subscription!(source, actor, instance::AsyncSchedulerInstance)
    subscription = AsyncSchedulerSubscription(instance)

    @async begin
        if !isunsubscribed(instance)
            tmp = on_subscribe!(source, actor, instance)
            if !isunsubscribed(instance)
                subscription.instance.subscription = tmp
            else
                unsubscribe!(tmp)
            end
        end
    end

    return subscription
end
