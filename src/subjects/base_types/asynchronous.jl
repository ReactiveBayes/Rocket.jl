export AsynchronousSubject, AsynchronousSubjectFactory

import Base: show

# -------------------- #
# Asynchronous subject #
# -------------------- #

struct AsynchronousSubjectNextMessage{D}
    data::D
end

struct AsynchronousSubjectErrorMessage
    err
end

struct AsynchronousSubjectCompleteMessage end

const AsynchronousSubjectMessage{D} = Union{AsynchronousSubjectNextMessage{D}, AsynchronousSubjectErrorMessage, AsynchronousSubjectCompleteMessage}

"""
    AsynchronousSubject{D}()

AsynchronousSubject is a base-type subject that asynchronously delivers all messages to the attached listeners using a different asynchronous task for each listener.

See also: [`as_subject`](@ref), [`make_subject`](@ref)
"""
mutable struct AsynchronousSubject{D} <: Actor{D}
    subscribers  :: Vector{Channel{AsynchronousSubjectMessage{D}}}
    is_completed :: Bool
    is_error     :: Bool
    last_error   :: Union{Nothing, Any}

    AsynchronousSubject{D}() where D = new(Vector{Channel{AsynchronousSubjectMessage{D}}}(), false, false, nothing)
end

as_subject(::Type{<:AsynchronousSubject{D}})      where D = ValidSubject{D}()
as_subscribable(::Type{<:AsynchronousSubject{D}}) where D = SimpleSubscribableTrait{D}()

is_exhausted(actor::AsynchronousSubject) = actor.is_completed || actor.is_error

function on_next!(subject::AsynchronousSubject{D}, data::D) where D
    channels = filter((s) -> isopen(s), subject.subscribers)
    __async_subject_multicast_message(channels, AsynchronousSubjectNextMessage{D}(data))
end

function on_error!(subject::AsynchronousSubject, err)
    if !subject.is_completed && !subject.is_error
        subject.is_error   = true
        subject.last_error = err

        channels = filter((s) -> isopen(s), subject.subscribers)
        __async_subject_multicast_message(channels, AsynchronousSubjectErrorMessage(err))
        __async_subject_close_channels(subject)
    end
end

function on_complete!(subject::AsynchronousSubject)
    if !subject.is_completed && !subject.is_error
        subject.is_completed = true

        channels = filter((s) -> isopen(s), subject.subscribers)
        __async_subject_multicast_message(channels, AsynchronousSubjectCompleteMessage())
        __async_subject_close_channels(subject)
    end
end

function __async_subject_multicast_message(channels::Vector{Channel{AsynchronousSubjectMessage{D}}}, message::AsynchronousSubjectMessage{D}) where D
    foreach((ch) -> push!(ch, message), channels)
end

function __async_subject_close_channels(subject::AsynchronousSubject{D}) where D
    foreach((ch) -> close(ch), subject.subscribers)
end

function on_subscribe!(subject::AsynchronousSubject{D}, actor) where D
    if subject.is_error
        error!(actor, subject.last_error)
        return VoidTeardown()
    elseif subject.is_completed
        complete!(actor)
        return VoidTeardown()
    else
        channel = Channel{AsynchronousSubjectMessage{D}}(Inf)

        task = @async begin
            while true
                message = take!(channel)::AsynchronousSubjectMessage{D}
                __async_actor_handle_event(actor, message)
            end
        end

        bind(channel, task)
        push!(subject.subscribers, channel)

        return AsynchronousSubjectSubscription(subject, channel)
    end
end

__async_actor_handle_event(actor, message::AsynchronousSubjectNextMessage{D}) where D  = next!(actor, message.data)
__async_actor_handle_event(actor, message::AsynchronousSubjectErrorMessage)            = error!(actor, message.err)
__async_actor_handle_event(actor, message::AsynchronousSubjectCompleteMessage)         = complete!(actor)

# --------------------------------- #
# Asynchronous subject subscription #
# --------------------------------- #

struct AsynchronousSubjectSubscription <: Teardown
    subject
    channel
end

as_teardown(::Type{<:AsynchronousSubjectSubscription}) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::AsynchronousSubjectSubscription)
    filter!((ch) -> ch !== subscription.channel, subscription.subject.subscribers)
    if isopen(subscription.channel)
        close(subscription.channel)
    end
    return nothing
end

Base.show(io::IO, subject::AsynchronousSubject{D}) where D       = print(io, "AsynchronousSubject($D)")
Base.show(io::IO, subscription::AsynchronousSubjectSubscription) = print(io, "AsynchronousSubjectSubscription()")

# ---------------------------- #
# Asynchronous subject factory #
# ---------------------------- #

struct AsynchronousSubjectFactory <: AbstractSubjectFactory end

create_subject(::Type{L}, factory::AsynchronousSubjectFactory) where L = AsynchronousSubject{L}()
