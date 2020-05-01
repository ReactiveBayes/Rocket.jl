
import Base: show, showerror

"""
    ChanneledAsyncScheduler

`ChanneledAsyncScheduler` executes scheduled actions asynchronously and uses `Channel` object to order different actions on a single asynchronous task

See also: [`getscheduler`](@ref), [`scheduled_subscription!`](@ref), [`scheduled_next!`](@ref), [`scheduled_error!`](@ref), [`scheduled_complete!`](@ref)
"""
struct ChanneledAsyncScheduler{N} end

Base.show(io::IO, ::Type{<:ChanneledAsyncScheduler}) = print(io, "ChanneledAsyncScheduler()")

function ChanneledAsyncScheduler(size::Int = typemax(Int))
    return ChanneledAsyncScheduler{size}()
end

makeinstance(::Type{D}, ::ChanneledAsyncScheduler{N}) where { D, N } = ChanneledAsyncSchedulerInstance{D}(N)

struct ChanneledAsyncSchedulerDataMessage{D}
    data :: D
end

struct ChanneledAsyncSchedulerErrorMessage
    err
end

struct ChanneledAsyncSchedulerCompleteMessage end

const ChanneledAsyncSchedulerMessage{D} = Union{ChanneledAsyncSchedulerDataMessage{D}, ChanneledAsyncSchedulerErrorMessage, ChanneledAsyncSchedulerCompleteMessage}

mutable struct ChanneledAsyncSchedulerInstanceProps
    isunsubscribed :: Bool
    subscription   :: Teardown
end

struct ChanneledAsyncSchedulerInstance{D}
    channel :: Channel{ChanneledAsyncSchedulerMessage{D}}
    props   :: ChanneledAsyncSchedulerInstanceProps

    ChanneledAsyncSchedulerInstance{D}(size::Int = typemax(Int)) where D = begin
        return new(Channel{ChanneledAsyncSchedulerMessage{D}}(size), ChanneledAsyncSchedulerInstanceProps(false, VoidTeardown()))
    end
end

isunsubscribed(instance::ChanneledAsyncSchedulerInstance) = instance.props.isunsubscribed
getchannel(instance::ChanneledAsyncSchedulerInstance) = instance.channel

function dispose(instance::ChanneledAsyncSchedulerInstance)
    if !isunsubscribed(instance)
        unsubscribe!(instance.props.subscription)
        instance.props.isunsubscribed = true
        close(instance.channel)
    end
end

function __process_channeled_message(instance::ChanneledAsyncSchedulerInstance{D}, message::ChanneledAsyncSchedulerDataMessage{D}, actor) where D
    on_next!(actor, message.data)
end

function __process_channeled_message(instance::ChanneledAsyncSchedulerInstance, message::ChanneledAsyncSchedulerErrorMessage, actor)
    dispose(instance)
    on_error!(actor, message.err)
end

function __process_channeled_message(instance::ChanneledAsyncSchedulerInstance, message::ChanneledAsyncSchedulerCompleteMessage, actor)
    dispose(instance)
    on_complete!(actor)
end

struct ChanneledAsyncSchedulerSubscription{ H <: ChanneledAsyncSchedulerInstance } <: Teardown
    instance :: H
end

as_teardown(::Type{ <: ChanneledAsyncSchedulerSubscription}) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::ChanneledAsyncSchedulerSubscription)
    dispose(subscription.instance)
    return nothing
end

function scheduled_subscription!(source, actor, instance::ChanneledAsyncSchedulerInstance)
    subscription = ChanneledAsyncSchedulerSubscription(instance)

    scheduling = @async begin
        while !isunsubscribed(instance)
            message = take!(getchannel(instance))
            if !isunsubscribed(instance)
                __process_channeled_message(instance, message, actor)
            end
        end
    end

    bind(getchannel(instance), scheduling)

    @async begin
        if !isunsubscribed(instance)
            tmp = on_subscribe!(source, actor, instance)
            if !isunsubscribed(instance)
                subscription.instance.props.subscription = tmp
            else
                unsubscribe!(tmp)
            end
        end
    end

    return subscription
end

function scheduled_next!(actor, value::D, instance::ChanneledAsyncSchedulerInstance{D}) where { D }
    put!(getchannel(instance), ChanneledAsyncSchedulerDataMessage{D}(value))
end

function scheduled_error!(actor, err, instance::ChanneledAsyncSchedulerInstance)
    put!(getchannel(instance), ChanneledAsyncSchedulerErrorMessage(err))
end

function scheduled_complete!(actor, instance::ChanneledAsyncSchedulerInstance)
    put!(getchannel(instance), ChanneledAsyncSchedulerCompleteMessage())
end
