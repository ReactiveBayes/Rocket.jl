export PendingSubject, PendingSubjectFactory

import Base: show

"""
    PendingSubject(::Type{D}) where D
    PendingSubject(::Type{D}, factory::F) where { D, F <: AbstractFactory }
    PendingSubject(::Type{D}, subject::S) where { D, S }

A variant of Subject that emits its last value on completion.
Reemits last value on further subscriptions and then completes.

See also: [`PendingSubjectFactory`](@ref), [`Subject`](@ref), [`SubjectFactory`](@ref)
"""
function PendingSubject end

"""
    PendingSubjectFactory(factory::F) where { F <: AbstractSubjectFactory }
    PendingSubjectFactory(; scheduler::H = AsapScheduler()) where { H <: AbstractScheduler }

A variant of SubjectFactory that creates an instance of PendingSubject.

See also: [`SubjectFactory`](@ref), [`AbstractSubjectFactory`](@ref), [`PendingSubject`](@ref), [`Subject`](@ref)
"""
function PendingSubjectFactory end

##

mutable struct PendingSubjectInstance{D, S} <: AbstractSubject{D}
    subject :: Union{Nothing, S}
    last    :: Union{Nothing, D}
end

Base.show(io::IO, ::PendingSubjectInstance{D, S}) where { D, S } = print(io, "PendingSubject($D, $S)")

function PendingSubject(::Type{D}) where D
    return PendingSubject(D, SubjectFactory(AsapScheduler()))
end

function PendingSubject(::Type{D}, factory::F) where { D, F <: AbstractSubjectFactory }
    return PendingSubject(D, create_subject(D, factory))
end

function PendingSubject(::Type{D}, subject::S) where { D, S }
    return as_pending_subject(D, as_subject(S), subject)
end

as_pending_subject(::Type{D},  ::InvalidSubject,    subject)    where D          = throw(InvalidSubjectTraitUsageError(subject))
as_pending_subject(::Type{D1}, ::ValidSubject{D2},  subject)    where { D1, D2 } = throw(InconsistentSubjectDataTypesError{D1, D2}(subject))
as_pending_subject(::Type{D},  ::ValidSubject{D},   subject::S) where { D, S }   = PendingSubjectInstance{D, S}(subject, nothing)

##

getlast(subject::PendingSubjectInstance)         = subject.last
setlast!(subject::PendingSubjectInstance, value) = subject.last = value

isdisposed(subject::PendingSubjectInstance) = subject.subject === nothing
dispose(subject::PendingSubjectInstance)    = subject.subject = nothing


##

function on_next!(subject::PendingSubjectInstance{D}, data::D) where D
    if !isdisposed(subject)
        setlast!(subject, data)
    end
end

function on_error!(subject::PendingSubjectInstance, err)
    if !isdisposed(subject)
        error!(subject.subject, err)
    end
end

function on_complete!(subject::PendingSubjectInstance)
    if !isdisposed(subject)
        last = getlast(subject)
        if last !== nothing
            next!(subject.subject, last)
        end
        complete!(subject.subject)
        dispose(subject)
    end
end

##

function on_subscribe!(subject::PendingSubjectInstance, actor)
    if isdisposed(subject)
        last = getlast(subject)
        if last !== nothing
            next!(actor, last)
        end
        complete!(actor)
        return voidTeardown
    else
        return subscribe!(subject.subject, actor)
    end
end

##

struct PendingSubjectFactoryInstance{ F <: AbstractSubjectFactory } <: AbstractSubjectFactory
    factory :: F
end

Base.show(io::IO, subject::PendingSubjectFactoryInstance{F}) where F = print(io, "PendingSubjectFactoryInstance($F)")

create_subject(::Type{L}, factory::PendingSubjectFactoryInstance) where L = PendingSubject(L, factory.factory)

function PendingSubjectFactory(factory::F) where { F <: AbstractSubjectFactory }
    return PendingSubjectFactoryInstance(factory)
end

function PendingSubjectFactory(; scheduler::H = AsapScheduler()) where { H <: AbstractScheduler }
    return PendingSubjectFactoryInstance(SubjectFactory{H}(scheduler))
end
