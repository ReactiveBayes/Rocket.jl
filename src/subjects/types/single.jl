export SingleSubject, as_subscribable, on_subscribe!
export SingleSubjectSubscription, as_teardown, on_unsubscribe!
export on_next!, on_error!, on_complete!, is_exhausted

export SingleSubjectFactory, create_subject

import Base: show

mutable struct SingleSubject{D} <: Actor{D}
    value        :: Union{Nothing, D}
    pending      :: Union{Nothing, Vector{AbstractActor{D}}}
    is_completed :: Bool
    is_error     :: Bool
    last_error   :: Union{Nothing, Any}

    SingleSubject{D}(initial::Union{Nothing, D} = nothing) where D = begin
        subject = new(initial, nothing, false, false, nothing)

        if initial === nothing
            subject.pending = Vector{AbstractActor{D}}()
        end

        return subject
    end
end

as_subject(::Type{<:SingleSubject{D}})      where D = ValidSubject{D}()
as_subscribable(::Type{<:SingleSubject{D}}) where D = ValidSubscribable{D}()

is_exhausted(actor::SingleSubject) = actor.is_completed || actor.is_error

function on_next!(subject::SingleSubject{D}, data::D) where D
    subject.value = data
    _notify_pending_actors_data(subject, data)
end

function on_error!(subject::SingleSubject, err)
    subject.is_error   = true
    subject.last_error = err
    _notify_pending_actors_error(subject, err)
end

function on_complete!(subject::SingleSubject)
    subject.is_completed = true
    _notify_pending_actors_complete(subject)
end

function _notify_pending_actors_data(subject::SingleSubject{D}, data::D) where D
    if subject.pending !== nothing
        for actor in subject.pending
            next!(actor, data)
            complete!(actor)
        end
        subject.pending = nothing
    end
end

function _notify_pending_actors_error(subject::SingleSubject, err)
    if subject.pending !== nothing
        for actor in subject.pending
            error!(actor, err)
        end
        subject.pending = nothing
    end
end

function _notify_pending_actors_complete(subject::SingleSubject)
    if subject.pending !== nothing
        for actor in subject.pending
            complete!(actor)
        end
        subject.pending = nothing
    end
end

function on_subscribe!(subject::SingleSubject, actor)
    if subject.is_error
        error!(actor, subject.last_error)
        return VoidTeardown()
    elseif subject.is_completed && subject.value === nothing
        complete!(actor)
        return VoidTeardown()
    elseif subject.value !== nothing
        next!(actor, subject.value)
        complete!(actor)
        return VoidTeardown()
    else
        push!(subject.pending, actor)
        return SingleSubjectSubscription(subject, actor)
    end
end

struct SingleSubjectSubscription
    subject
    actor
end

as_teardown(::Type{<:SingleSubjectSubscription}) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::SingleSubjectSubscription)
    if subscription.subject.pending !== nothing
        filter!((actor) -> actor !== subscription.actor, subscription.subject.pending)
    end
    return nothing
end

Base.show(io::IO, subject::SingleSubject{D}) where D       = print(io, "SingleSubject($D)")
Base.show(io::IO, subscription::SingleSubjectSubscription) = print(io, "SingleSubjectSubscription()")

# ----------------------- #
# Single Subject factory  #
# ----------------------- #

struct SingleSubjectFactory <: AbstractSubjectFactory
    initial

    SingleSubjectFactory(initial = nothing) = new(initial)
end

function create_subject(::Type{L}, factory::SingleSubjectFactory) where L
    if factory.initial !== nothing
        return SingleSubject{L}(convert(L, factory.initial))
    else
        return SingleSubject{L}()
    end
end
