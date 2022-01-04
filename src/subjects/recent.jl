export RecentSubject, RecentSubjectFactory

import Base: show, similar

"""
    RecentSubject(::Type{D}) where D
    RecentSubject(::Type{D}, factory::F) where { D, F <: AbstractSubjectFactory }
    RecentSubject(::Type{D}, subject::S) where { D, S }

A variant of Subject that emits its recent value whenever it is subscribed to.

See also: [`RecentSubjectFactory`](@ref), [`Subject`](@ref), [`SubjectFactory`](@ref)
"""
mutable struct RecentSubject{D, S} <: Subscribable{D}
    subject :: S
    recent  :: Union{D, Blank}
end

getscheduler(subject::RecentSubject) = getscheduler(subject.subject)

Base.show(io::IO, ::RecentSubject{D, S}) where { D, S } = print(io, "RecentSubject($D, $S)")

Base.similar(subject::RecentSubject{D, S}) where { D, S } = RecentSubject(D, similar(subject.subject))

RecentSubject(::Type{D}) where D = RecentSubject(D, SubjectFactory(AsapScheduler()))

RecentSubject(::Type{D}, factory::F) where { D, F <: AbstractSubjectFactory } = RecentSubject(D, create_subject(D, factory))
RecentSubject(::Type{D}, subject::S) where { D, S }                           = RecentSubject{D, S}(subject, blank)

##

getrecent(subject::RecentSubject)         = subject.recent
setrecent!(subject::RecentSubject, value) = subject.recent = value

##

function on_next!(subject::RecentSubject{D}, data::D) where D
    setrecent!(subject, data)
    on_next!(subject.subject, data)
end

on_error!(subject::RecentSubject, err) = on_error!(subject.subject, err)
on_complete!(subject::RecentSubject)   = on_complete!(subject.subject)

##

function on_subscribe!(subject::RecentSubject, actor)
    recent = getrecent(subject)
    if recent !== blank
        on_next!(actor, recent)
    end
    return on_subscribe!(subject.subject, actor)
end

##

"""
    RecentSubjectFactory(factory::F) where { F <: AbstractSubjectFactory }
    RecentSubjectFactory(; scheduler::H = AsapScheduler()) where { H }

A variant of SubjectFactory that creates an instance of RecentSubject.

See also: [`SubjectFactory`](@ref), [`AbstractSubjectFactory`](@ref), [`RecentSubject`](@ref), [`Subject`](@ref)
"""
struct RecentSubjectFactory{ F <: AbstractSubjectFactory } <: AbstractSubjectFactory
    factory :: F
end

Base.show(io::IO, ::RecentSubjectFactory{F}) where F = print(io, "RecentSubjectFactory($F)")

create_subject(::Type{L}, factory::RecentSubjectFactory) where L = RecentSubject(L, factory.factory)

function RecentSubjectFactory(; scheduler::H = AsapScheduler()) where { H }
    return RecentSubjectFactory(SubjectFactory{H}(scheduler))
end

##
