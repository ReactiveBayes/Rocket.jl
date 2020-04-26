export PendingSubject, PendingSubjectFactory
export make_pending_subject, make_pending_subject_factory

# TODO: Untested and undocumented

mutable struct PendingSubject{D, S} <: Actor{D}
    value        :: Union{Nothing, D}
    subject      :: Union{Nothing, S}
end

as_subject(::Type{<:PendingSubject{D}})      where D = ValidSubject{D}()
as_subscribable(::Type{<:PendingSubject{D}}) where D = SimpleSubscribableTrait{D}()

is_exhausted(actor::PendingSubject) = is_exhausted(actor.subject)

function on_next!(subject::PendingSubject{D}, data::D) where D
    subject.value = data
    if subject.subject !== nothing
        next!(subject.subject, data)
        complete!(subject.subject)
        subject.subject = nothing
    end
end

function on_error!(subject::PendingSubject, err)
    if subject.subject !== nothing
        error!(subject.subject, err)
    end
end

function on_complete!(subject::PendingSubject)
    if subject.subject !== nothing
        complete!(subject.subject)
    end
end

function on_subscribe!(subject::PendingSubject, actor)
    if subject.value !== nothing
        next!(actor, subject.value)
        complete!(actor)
        return VoidTeardown()
    else
        return subscribe!(subject.subject, actor)
    end
end

# -------------------------------- #
# Pending subject create operators #
# -------------------------------- #

make_pending_subject(::Type{T}, subject_factory::F) where T where { F <: AbstractSubjectFactory } = make_pending_subject(T, create_subject(T, subject_factory))
make_pending_subject(::Type{T}, subject::S)         where T where S                               = as_pending_subject(T, as_subject(S), subject)

as_pending_subject(::Type{T},  ::InvalidSubject,   subject)    where T                   = throw(InvalidSubjectTraitUsageError(subject))
as_pending_subject(::Type{T1}, ::ValidSubject{T2}, subject::S) where T1 where T2 where S = throw(InconsistentSubjectDataTypesError{T1, T2}(subject))
as_pending_subject(::Type{T},  ::ValidSubject{T},  subject::S) where T where S           = PendingSubject{T, S}(nothing, subject)

make_pending_subject(::Type{T}; mode::Val{M} = DEFAULT_SUBJECT_MODE) where T where M = make_pending_subject(T, make_subject_factory(mode = mode))

# ----------------------- #
# Single Subject factory  #
# ----------------------- #

struct PendingSubjectFactory{M} <: AbstractSubjectFactory end

create_subject(::Type{L}, factory::PendingSubjectFactory{M}) where L where M = make_pending_subject(T; mode = Val(M))

make_pending_subject_factory(; mode::Val{M} = DEFAULT_SUBJECT_MODE) where M = PendingSubjectFactory{M}()
