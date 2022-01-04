export PendingSubject, PendingSubjectFactory

import Base: show, similar

"""
    PendingSubject(::Type{D}) where D
    PendingSubject(::Type{D}, factory::F) where { D, F <: AbstractFactory }
    PendingSubject(::Type{D}, subject::S) where { D, S }

A variant of Subject that emits its last value on completion.
Reemits last value on further subscriptions and then completes.

See also: [`PendingSubjectFactory`](@ref), [`Subject`](@ref), [`SubjectFactory`](@ref)
"""
mutable struct PendingSubject{D, S} <: Subscribable{D}
    subject :: S
    last    :: Union{Blank, D}
end

getscheduler(subject::PendingSubject) = getscheduler(subject.subject)

##

Base.show(io::IO, ::PendingSubject{D, S}) where { D, S } = print(io, "PendingSubject($D, $S)")

Base.similar(subject::PendingSubject{D, S}) where { D, S } = PendingSubject(D, similar(subject.subject))

PendingSubject(::Type{D}) where D = PendingSubject(D, SubjectFactory(AsapScheduler()))

PendingSubject(::Type{D}, factory::F) where { D, F <: AbstractSubjectFactory } = PendingSubject(D, create_subject(D, factory))
PendingSubject(::Type{D}, subject::S) where { D, S }                           = PendingSubject{D, S}(subject, blank)

##

getlast(subject::PendingSubject)         = subject.last
setlast!(subject::PendingSubject, value) = subject.last = value

##

function on_next!(subject::PendingSubject{D}, data::D) where D
    if isactive(subject.subject)
        setlast!(subject, data)
    end
end

function on_error!(subject::PendingSubject, err)
    if isactive(subject.subject)
        on_error!(subject.subject, err)
    end
end

function on_complete!(subject::PendingSubject)
    if isactive(subject.subject)
        last = getlast(subject)
        if last !== blank
            on_next!(subject.subject, last)
        end
        on_complete!(subject.subject)
    end
end

##

function on_subscribe!(subject::PendingSubject, actor)
    if iscompleted(subject.subject)
        last = getlast(subject)
        if last !== blank
            on_next!(actor, last)
        end
        on_complete!(actor)
        return noopSubscription
    else
        return on_subscribe!(subject.subject, actor)
    end
end

##

"""
    PendingSubjectFactory(factory::F) where { F <: AbstractSubjectFactory }
    PendingSubjectFactory(; scheduler::H = AsapScheduler()) where { H }

A variant of SubjectFactory that creates an instance of PendingSubject.

See also: [`SubjectFactory`](@ref), [`AbstractSubjectFactory`](@ref), [`PendingSubject`](@ref), [`Subject`](@ref)
"""
struct PendingSubjectFactory{ F <: AbstractSubjectFactory } <: AbstractSubjectFactory
    factory :: F
end


Base.show(io::IO, subject::PendingSubjectFactory{F}) where F = print(io, "PendingSubjectFactory($F)")

create_subject(::Type{L}, factory::PendingSubjectFactory) where L = PendingSubject(L, factory.factory)

function PendingSubjectFactory(; scheduler::H = AsapScheduler()) where { H }
    return PendingSubjectFactory(SubjectFactory{H}(scheduler))
end
