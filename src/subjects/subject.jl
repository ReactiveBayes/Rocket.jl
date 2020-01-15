export Subject, as_subscribable, on_subscribe!
export SubjectSubscription, as_teardown, on_unsubscribe!
export on_next!, on_error!, on_complete!, is_exhausted
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

"""
    Subject

A Subject is a special type of Observable that allows values to be multicasted to many Actors. Subjects are like event emitters.
Every Subject is an Observable and an Actor. You can subscribe to a Subject,
and you can call `next!` to feed values as well as `error!` and `complete!`.

See also: [`BehaviorSubject`](@ref), [`ReplaySubject`](@ref)
"""
mutable struct Subject{D} <: Actor{D}
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
                    message = take!(channel)::SubjectMessage{D}
                    _subject_handle_event(subject, message)
                end
            catch err
                @warn "An exception occured during Subject data event handling: $err"
                _subject_handle_event(subject, SubjectErrorMessage(err))
            end
        end

        bind(channel, task)

        subject
    end
end

as_subscribable(::Type{<:Subject{D}}) where D = ValidSubscribable{D}()

is_exhausted(actor::Subject) = actor.is_completed || actor.is_error

on_next!(subject::Subject{D}, data::D) where D = put!(subject.channel, SubjectNextMessage{D}(data))
on_error!(subject::Subject{D}, error)  where D = put!(subject.channel, SubjectErrorMessage(error))
on_complete!(subject::Subject{D})      where D = put!(subject.channel, SubjectCompleteMessage())

function _subject_handle_event(subject::Subject{D}, message::SubjectNextMessage{D}) where D
    failed_actors = Vector{AbstractActor{D}}()

    data = message.data
    for actor in subject.actors
        try
            next!(actor, data)
        catch err
            @warn "An exception occured during Subject data event handling for actor $(typeof(actor)): $err"
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
    close(subject.channel)
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


struct SubjectSubscription <: Teardown
    subject
    actor
end

as_teardown(::Type{<:SubjectSubscription}) = UnsubscribableTeardownLogic()

function on_subscribe!(subject::Subject, actor)
    if subject.is_error
        error!(actor, subject.last_error)
        return VoidTeardown()
    elseif subject.is_completed
        complete!(actor)
        return VoidTeardown()
    else
        push!(subject.actors, actor)
        return SubjectSubscription(subject, actor)
    end
end

function on_unsubscribe!(subscription::SubjectSubscription)
    filter!((actor) -> actor !== subscription.actor, subscription.subject.actors)
    return nothing
end

Base.show(io::IO, subject::Subject{D}) where D       = print(io, "Subject($D)")
Base.show(io::IO, subscription::SubjectSubscription) = print(io, "SubjectSubscription()")

function close(subject::Subject{D}) where D
    _subject_handle_event(subject, SubjectCompleteMessage())
end
