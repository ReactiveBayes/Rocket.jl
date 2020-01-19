export SynchronousSubject, as_subscribable, on_subscribe!
export SynchronousSubjectSubscription, as_teardown, on_unsubscribe!
export on_next!, on_error!, on_complete!, is_exhausted

import Base: show

# ------------------- #
# Synchronous subject #
# ------------------- #

mutable struct SynchronousSubject{D} <: Actor{D}
    actors       :: Vector{Any}
    is_completed :: Bool
    is_error     :: Bool
    last_error   :: Union{Nothing, Any}

    SynchronousSubject{D}() where D = new(Vector{Any}(), false, false, nothing)
end

as_subject(::Type{<:SynchronousSubject{D}})      where D = ValidSubject{D}()
as_subscribable(::Type{<:SynchronousSubject{D}}) where D = ValidSubscribable{D}()

is_exhausted(actor::SynchronousSubject) = actor.is_completed || actor.is_error

function on_next!(subject::SynchronousSubject{D}, data::D) where D
    failed_actors = Vector{Any}()
    actors        = copy(subject.actors)

    for actor in actors
        try
            next!(actor, data)
        catch err
            @warn "An exception occured during Subject data event handling for actor $(typeof(actor)): $err"
            error!(actor, err)
            push!(failed_actors, actor)
        end
    end

    __sync_subject_unsubscribe_actors(subject, failed_actors)
end

function on_error!(subject::SynchronousSubject, err)
    if !subject.is_completed && !subject.is_error
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

        __sync_subject_unsubscribe_all(subject)
    end
end

function on_complete!(subject::SynchronousSubject)
    if !subject.is_completed && !subject.is_error
        subject.is_completed = true

        for actor in subject.actors
            try
                complete!(actor)
            catch exception
                @warn "An exception occured during complete! invocation in subject $(subject) for actor $(actor). Cannot deliver error $(error)"
                @warn exception
            end
        end

        __sync_subject_unsubscribe_all(subject)
    end
end

function __sync_subject_unsubscribe_actors(subject::SynchronousSubject{D}, actors) where D
    foreach((actor) -> unsubscribe!(SyncSubjectSubscription(subject, actor)), actors)
end

function __sync_subject_unsubscribe_all(subject::SynchronousSubject)
    __sync_subject_unsubscribe_actors(subject, subject.actors)
end

function on_subscribe!(subject::SynchronousSubject, actor)
    if subject.is_error
        error!(actor, subject.last_error)
        return VoidTeardown()
    elseif subject.is_completed
        complete!(actor)
        return VoidTeardown()
    else
        push!(subject.actors, actor)
        return SynchronousSubjectSubscription(subject, actor)
    end
end

# -------------------------------- #
# Synchronous subject subscription #
# -------------------------------- #

struct SynchronousSubjectSubscription <: Teardown
    subject
    actor
end

as_teardown(::Type{<:SynchronousSubjectSubscription}) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::SynchronousSubjectSubscription)
    filter!((actor) -> actor !== subscription.actor, subscription.subject.actors)
    return nothing
end

Base.show(io::IO, subject::SynchronousSubject{D}) where D       = print(io, "SynchronousSubject($D)")
Base.show(io::IO, subscription::SynchronousSubjectSubscription) = print(io, "SynchronousSubjectSubscription()")

# --------------------------- #
# Synchronous Subject factory #
# --------------------------- #

struct SynchronousSubjectFactory <: AbstractSubjectFactory end

create_subject(::Type{L}, factory::SynchronousSubjectFactory) where L = SynchronousSubject{L}()
