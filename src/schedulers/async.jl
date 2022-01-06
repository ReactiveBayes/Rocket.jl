export AsyncScheduler

import Base: size, show, similar

"""
    AsyncScheduler

`AsyncScheduler` executes scheduled actions asynchronously and uses the `Channel` object to order different actions on a single asynchronous task. 
Creates a new channel for each new observable execution (aka [`subscribe!`](@ref)).

See also: [`Channel`]
"""
struct AsyncScheduler <: AbstractSchedulerFactory
    size :: Int

    function AsyncScheduler(size::Int = typemax(Int))
        return new(size)
    end
end

create_scheduler(::Type{D}, factory::AsyncScheduler) where D = AsyncSchedulerInstance(D, size(factory))

Base.size(scheduler::AsyncScheduler)    = scheduler.size
Base.show(io::IO, ::AsyncScheduler)     = print(io, "AsyncScheduler()")
Base.similar(scheduler::AsyncScheduler) = AsyncScheduler(size(scheduler))

struct AsyncSchedulerDataMessage{D}
    data :: D
    actor
end

struct AsyncSchedulerErrorMessage
    err
    actor
end

struct AsyncSchedulerCompleteMessage 
    actor
end

const AsyncSchedulerMessage{D} = Union{AsyncSchedulerDataMessage{D}, AsyncSchedulerErrorMessage, AsyncSchedulerCompleteMessage}

mutable struct AsyncSchedulerInstance{D}
    channel        :: Channel{AsyncSchedulerMessage{D}}
    isinvoked      :: Bool
    isunsubscribed :: Bool
    subscription   :: Subscription
end

Base.show(io::IO, ::AsyncSchedulerInstance{D})            where D = print(io, "AsyncSchedulerInstance($D)")
Base.show(io::IO, ::Type{ <: AsyncSchedulerInstance{D} }) where D = print(io, "AsyncSchedulerInstance($D)")

function AsyncSchedulerInstance(::Type{D}, size::Int = typemax(Int)) where D
    return AsyncSchedulerInstance{D}(Channel{AsyncSchedulerMessage{D}}(size), false, false, noopSubscription)
end

isinvoked(instance::AsyncSchedulerInstance)   = instance.isinvoked
setinvoked!(instance::AsyncSchedulerInstance) = instance.isinvoked = true

isunsubscribed(instance::AsyncSchedulerInstance)   = instance.isunsubscribed
setunsubscribed!(instance::AsyncSchedulerInstance) = instance.isunsubscribed = true

getchannel(instance::AsyncSchedulerInstance)       = instance.channel

function dispose(instance::AsyncSchedulerInstance)
    if !isunsubscribed(instance)
        setunsubscribed!(instance)
        close(getchannel(instance))
        @async begin
            on_unsubscribe!(instance.subscription)
        end
    end
end

function __process_channeled_message(instance::AsyncSchedulerInstance, message::AsyncSchedulerDataMessage)
    on_next!(message.actor, message.data)
end

function __process_channeled_message(instance::AsyncSchedulerInstance, message::AsyncSchedulerErrorMessage)
    on_error!(message.actor, message.err)
    dispose(instance)
end

function __process_channeled_message(instance::AsyncSchedulerInstance, message::AsyncSchedulerCompleteMessage)
    on_complete!(message.actor)
    dispose(instance)
end

struct AsyncSchedulerSubscription{ H <: AsyncSchedulerInstance } <: Subscription
    instance :: H
end

getscheduler(subscription::AsyncSchedulerSubscription) = subscription.instance

Base.show(io::IO, ::AsyncSchedulerSubscription) = print(io, "AsyncSchedulerSubscription()")

function unsubscribe!(instance::AsyncSchedulerInstance, subscription)
    @assert instance === getscheduler(subscription) "Invalid async unsubscription. `unsubscribe!` should be invoked with the same async scheduler instance"
    dispose(instance)
    return nothing
end

function subscribe!(instance::AsyncSchedulerInstance, source, actor)
    @assert !isinvoked(instance) "AsyncSchedulerInstance has been used for subscription already. It is not allowed to use the same async instance for multiple subscriptions."

    sactor       = ScheduledActor(instance, actor)
    subscription = AsyncSchedulerSubscription(instance)

    channeling_task = @async begin
        while !isunsubscribed(instance)
            message = take!(getchannel(instance))
            if !isunsubscribed(instance)
                __process_channeled_message(instance, message)
            end
        end
    end

    @async begin
        if !isunsubscribed(instance)
            tmp = on_subscribe!(source, sactor)
            if !isunsubscribed(instance)
                subscription.instance.subscription = tmp
            else
                on_unsubscribe!(tmp)
            end
        end
    end

    bind(getchannel(instance), channeling_task)
    setinvoked!(instance)

    return subscription
end

next!(instance::AsyncSchedulerInstance{D}, actor, value::D) where { D } = put!(getchannel(instance), AsyncSchedulerDataMessage{D}(value, actor))
error!(instance::AsyncSchedulerInstance, actor, err)                    = put!(getchannel(instance), AsyncSchedulerErrorMessage(err, actor))
complete!(instance::AsyncSchedulerInstance, actor)                      = put!(getchannel(instance), AsyncSchedulerCompleteMessage(actor))
