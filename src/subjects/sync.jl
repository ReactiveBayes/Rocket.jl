export SyncSubject, as_subscribable, on_subscribe!
export SyncSubjectSubscription, as_teardown, on_unsubscribe!
export on_next!, on_error!, on_complete!, is_exhausted

import Base: show

mutable struct SyncSubject{D} <: Actor{D}
    actors       :: Array{AbstractActor{D}, 1}
    is_completed :: Bool
    is_error     :: Bool
    last_error   :: Union{Nothing, Any}

    SyncSubject{D}() where D = begin
        actors       = Array{AbstractActor{D}, 1}()
        is_completed = false
        is_error     = false
        last_error   = nothing

        return new(actors, is_completed, is_error, last_error)
    end
end

as_subject(::Type{<:SyncSubject{D}})      where D = ValidSubject{D}()
as_subscribable(::Type{<:SyncSubject{D}}) where D = ValidSubscribable{D}()

is_exhausted(actor::SyncSubject) = actor.is_completed || actor.is_error

function on_next!(subject::SyncSubject{D}, data::D) where D
    failed_actors = Vector{AbstractActor{D}}()
    actors = copy(subject.actors)

    for actor in actors
        try
            next!(actor, data)
        catch err
            @warn "An exception occured during Subject data event handling for actor $(typeof(actor)): $err"
            error!(actor, err)
            push!(failed_actors, actor)
        end
    end

    _sync_subject_unsubscribe_actors(subject, failed_actors)
end

function on_error!(subject::SyncSubject, err)
    subject.is_error   = true
    subject.last_error = error

    for actor in subject.actors
        try
            error!(actor, err)
        catch exception
            @warn "An exception occured during error! invocation in subject $(subject) for actor $(actor). Cannot deliver error $(error)"
            @warn exception
        end
    end

    _sync_subject_unsubscribe_all(subject)
end

function on_complete!(subject::SyncSubject)
    subject.is_completed = true

    for actor in subject.actors
        try
            complete!(actor)
        catch exception
            @warn "An exception occured during complete! invocation in subject $(subject) for actor $(actor). Cannot deliver error $(error)"
            @warn exception
        end
    end

    _sync_subject_unsubscribe_all(subject)
end

function _sync_subject_unsubscribe_actors(subject::SyncSubject{D}, actors::Vector{AbstractActor{D}}) where D
    for actor in actors
        unsubscribe!(SyncSubjectSubscription(subject, actor))
    end
end

function _sync_subject_unsubscribe_all(subject::SyncSubject)
    _sync_subject_unsubscribe_actors(subject, subject.actors)
end


struct SyncSubjectSubscription <: Teardown
    subject
    actor
end

as_teardown(::Type{<:SyncSubjectSubscription}) = UnsubscribableTeardownLogic()

function on_subscribe!(subject::SyncSubject, actor)
    if subject.is_error
        error!(actor, subject.last_error)
        return VoidTeardown()
    elseif subject.is_completed
        complete!(actor)
        return VoidTeardown()
    else
        push!(subject.actors, actor)
        return SyncSubjectSubscription(subject, actor)
    end
end

function on_unsubscribe!(subscription::SyncSubjectSubscription)
    filter!((actor) -> actor !== subscription.actor, subscription.subject.actors)
    return nothing
end

Base.show(io::IO, subject::SyncSubject{D}) where D       = print(io, "SyncSubject($D)")
Base.show(io::IO, subscription::SyncSubjectSubscription) = print(io, "SyncSubjectSubscription()")

# ----------------------- #
# Sync Subject factory    #
# ----------------------- #

struct SyncSubjectFactory <: AbstractSubjectFactory end

create_subject(::Type{L}, factory::SyncSubjectFactory) where L = SyncSubject{L}()
