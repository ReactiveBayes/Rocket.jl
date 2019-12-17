export Subject, on_subscribe!
export SubjectSubscription, as_teardown, on_unsubscribe!
export as_actor, on_next!, on_error!, on_complete!
export close

import Base: show
import Base: close

struct SubjectNextMessage{D}
    data::D
end

struct SubjectErrorMessage
    error
end

struct SubjectCompleteMessage end

const SubjectMessage{D} = Union{SubjectNextMessage{D}, SubjectErrorMessage, SubjectCompleteMessage}

mutable struct Subject{D} <: Subscribable{D}
    channel      :: Channel{SubjectMessage{D}}
    actors       :: Array{AbstractActor{D}, 1}
    is_completed :: Bool
    is_error     :: Bool
    last_error   :: Union{Nothing, Any}

    Subject{D}() where D = begin
        channel      = Channel{SubjectMessage{D}}(Inf)
        actors       = Array{AbstractActor{D}, 1}()
        is_completed = false
        is_error     = false
        last_error   = nothing

        subject = new(channel, actors, is_completed, is_error, last_error)

        task = @async begin
            try
                while !subject.is_completed && !subject.is_error
                    message = take!(channel)
                    _subject_handle_event(subject, message)
                end
            catch e
                _subject_handle_event(subject, SubjectErrorMessage(e))
            end
        end

        bind(channel, task)

        subject
    end
end

function _subject_handle_event(subject::Subject{D}, message::SubjectNextMessage{D}) where D
    failed_actors = Vector{AbstractActor{D}}()

    data = message.data
    for actor in subject.actors
        try
            next!(actor, data)
        catch err
            error!(actor, err)
            push!(failed_actors, actor)
        end
    end

    _subject_unsubscribe_actors(subject, failed_actors)
end

function _subject_handle_event(subject::Subject{D}, message::SubjectErrorMessage) where D
    error = message.error

    subject.is_error   = true
    subject.last_error = error

    for actor in subject.actors
        try
            error!(actor, error)
        catch exception
            @warn "An exception occured during error! invocation in subject $(subject) for actor $(actor). Cannot deliver error $(error)"
            @warn exception
        end
    end

    _subject_unsubscribe_all(subject)
end

function _subject_handle_event(subject::Subject{D}, message::SubjectCompleteMessage) where D
    subject.is_completed = true

    for actor in subject.actors
        try
            complete!(actor)
        catch exception
            @warn "An exception occured during complete! invocation in subject $(subject) for actor $(actor). Cannot deliver error $(error)"
            @warn exception
        end
    end

    _subject_unsubscribe_all(subject)
    close(subject.channel)
end

function _subject_unsubscribe_actors(subject::Subject{D}, actors::Vector{AbstractActor{D}}) where D
    for actor in actors
        unsubscribe!(SubjectSubscription(subject, actor))
    end
end

function _subject_unsubscribe_all(subject::Subject{D}) where D
    _subject_unsubscribe_actors(subject, subject.actors)
end


struct SubjectSubscription{D, A <: AbstractActor{D}} <: Teardown
    subject :: Subject{D}
    actor   :: A
end

as_teardown(::Type{<:SubjectSubscription}) = UnsubscribableTeardownLogic()

function on_subscribe!(subject::Subject{D}, actor::A) where { A <: AbstractActor{D} } where D
    if subject.is_error
        error!(actor, subject.last_error)
        return VoidTeardown()
    elseif subject.is_completed
        complete!(actor)
        return VoidTeardown()
    else
        push!(subject.actors, actor)
        return SubjectSubscription{D, A}(subject, actor)
    end
end

function on_unsubscribe!(subscription::SubjectSubscription)
    filter!((actor) -> actor !== subscription.actor, subscription.subject.actors)
    return nothing
end

as_actor(::Type{<:Subject{D}}) where D = BaseActorTrait{D}()

on_next!(subject::Subject{D}, data::D) where D = put!(subject.channel, SubjectNextMessage{D}(data))
on_error!(subject::Subject{D}, error)  where D = put!(subject.channel, SubjectErrorMessage(error))
on_complete!(subject::Subject{D})      where D = put!(subject.channel, SubjectCompleteMessage())

Base.show(io::IO, subject::Subject)                  = print(io, "Subject [ with $(length(subject.actors)) actors listening ]")
Base.show(io::IO, subscription::SubjectSubscription) = print(io, "Subject subscription with $(subscription.actor) actor")

function close(subject::Subject{D}) where D
    _subject_handle_event(subject, SubjectCompleteMessage())
end
