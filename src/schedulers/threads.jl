
# experimental

import Base: show, similar

"""
    ThreadsScheduler

`ThreadsScheduler` executes scheduled actions in a different threads

See also: [`getscheduler`](@ref), [`scheduled_subscription!`](@ref), [`scheduled_next!`](@ref), [`scheduled_error!`](@ref), [`scheduled_complete!`](@ref)
"""
struct ThreadsScheduler <: AbstractScheduler end

Base.show(io::IO, ::ThreadsScheduler) = print(io, "ThreadsScheduler()")

mutable struct ThreadsSchedulerInstance
    isunsubscribed :: Bool
    subscription   :: Teardown
end

Base.similar(::ThreadsScheduler) = ThreadsScheduler()

makeinstance(::Type, ::ThreadsScheduler) = ThreadsSchedulerInstance(false, voidTeardown)

instancetype(::Type, ::Type{<:ThreadsScheduler}) = ThreadsSchedulerInstance

isunsubscribed(instance::ThreadsSchedulerInstance) = instance.isunsubscribed

function dispose(instance::ThreadsSchedulerInstance)
    if !isunsubscribed(instance)
        unsubscribe!(instance.subscription)
        instance.isunsubscribed = true
    end
end

macro schedule_onthread(expr)
    output = quote
        @static if VERSION >= v"1.3"
            if !isunsubscribed(instance)
                t = Threads.@spawn begin
                    if !isunsubscribed(instance)
                        $(expr)
                    end
                end
                @static if VERSION >= v"1.7"
                    Base.errormonitor(t)
                end
            end
        else
            $(expr)
        end
    end
    return esc(output)
end

function scheduled_next!(actor, value, instance::ThreadsSchedulerInstance)
    @schedule_onthread begin
        on_next!(actor, value)
    end
end

function scheduled_error!(actor, err, instance::ThreadsSchedulerInstance)
    @schedule_onthread begin
        dispose(instance)
        on_error!(actor, err)
    end
end

function scheduled_complete!(actor, instance::ThreadsSchedulerInstance)
    @schedule_onthread begin
        dispose(instance)
        on_complete!(actor)
    end
end

struct ThreadsSchedulerSubscription{ H <: ThreadsSchedulerInstance } <: Teardown
    instance :: H
end

as_teardown(::Type{ <: ThreadsSchedulerSubscription}) = UnsubscribableTeardownLogic()

Base.show(io::IO, ::ThreadsSchedulerSubscription) = print(io, "ThreadsSchedulerSubscription()")

function on_unsubscribe!(subscription::ThreadsSchedulerSubscription)
    dispose(subscription.instance)
    return nothing
end

function scheduled_subscription!(source, actor, instance::ThreadsSchedulerInstance)
    @static if VERSION >= v"1.3"
        subscription = ThreadsSchedulerSubscription(instance)
        t = Threads.@spawn begin
            if !isunsubscribed(instance)
                tmp = on_subscribe!(source, actor, instance)
                if !isunsubscribed(instance)
                    subscription.instance.subscription = tmp
                else
                    unsubscribe!(tmp)
                end
            end
        end
        @static if VERSION >= v"1.7"
            Base.errormonitor(t)
        end
        return subscription
    else
        @warn "ThreadsScheduler is not supported for Julia version < 1.3"
        return on_subscribe!(source, actor, instance)
    end
end
