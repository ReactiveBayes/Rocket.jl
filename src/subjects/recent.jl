export RecentSubject, RecentSubjectFactory

import Base: show, similar

"""
    RecentSubject(::Type{D}) where D
    RecentSubject(::Type{D}, factory::F) where { D, F <: AbstractSubjectFactory }
    RecentSubject(::Type{D}, subject::S) where { D, S }

A variant of Subject that emits its recent value whenever it is subscribed to.

See also: [`RecentSubjectFactory`](@ref), [`Subject`](@ref), [`SubjectFactory`](@ref)
"""
function RecentSubject end

"""
    RecentSubjectFactory(factory::F) where { F <: AbstractSubjectFactory }
    RecentSubjectFactory(; scheduler::H = AsapScheduler()) where { H <: AbstractScheduler }

A variant of SubjectFactory that creates an instance of RecentSubject.

See also: [`SubjectFactory`](@ref), [`AbstractSubjectFactory`](@ref), [`RecentSubject`](@ref), [`Subject`](@ref)
"""
function RecentSubjectFactory end

mutable struct RecentSubjectProps{D}
    recent :: Union{D, Nothing}
end

Base.show(io::IO, ::RecentSubjectProps) = print(io, "RecentSubjectProps()")

##

struct RecentSubjectInstance{D, S} <: AbstractSubject{D}
    subject :: S
    props   :: RecentSubjectProps{D}
end

Base.show(io::IO, ::RecentSubjectInstance{D, S}) where { D, S } = print(io, "RecentSubject($D, $S)")

Base.similar(subject::RecentSubjectInstance{D, S}) where { D, S } = RecentSubject(D, similar(subject.subject))

function RecentSubject(::Type{D}) where D
    return RecentSubject(D, SubjectFactory(AsapScheduler()))
end

function RecentSubject(::Type{D}, factory::F) where { D, F <: AbstractSubjectFactory }
    return RecentSubject(D, create_subject(D, factory))
end

function RecentSubject(::Type{D}, subject::S) where { D, S }
    return as_recent_subject(D, as_subject(S), subject)
end

as_recent_subject(::Type{D},  ::InvalidSubjectTrait,    subject)    where D          = throw(InvalidSubjectTraitUsageError(subject))
as_recent_subject(::Type{D1}, ::ValidSubjectTrait{D2},  subject)    where { D1, D2 } = throw(InconsistentSubjectDataTypesError{D1, D2}(subject))
as_recent_subject(::Type{D},  ::ValidSubjectTrait{D},   subject::S) where { D, S }   = RecentSubjectInstance{D, S}(subject, RecentSubjectProps{D}(nothing))

##

getrecent(subject::RecentSubjectInstance)         = subject.props.recent
setrecent!(subject::RecentSubjectInstance, value) = subject.props.recent = value

##

function on_next!(subject::RecentSubjectInstance{D}, data::D) where D
    setrecent!(subject, data)
    next!(subject.subject, data)
end

function on_error!(subject::RecentSubjectInstance, err)
    error!(subject.subject, err)
end

function on_complete!(subject::RecentSubjectInstance)
    complete!(subject.subject)
end

##

function on_subscribe!(subject::RecentSubjectInstance, actor)
    recent = getrecent(subject)
    if recent !== nothing
        next!(actor, recent)
    end
    return subscribe!(subject.subject, actor)
end

##

struct RecentSubjectFactoryInstance{ F <: AbstractSubjectFactory } <: AbstractSubjectFactory
    factory :: F
end

Base.show(io::IO, ::RecentSubjectFactoryInstance{F}) where F = print(io, "RecentSubjectFactory($F)")

create_subject(::Type{L}, factory::RecentSubjectFactoryInstance) where L = RecentSubject(L, factory.factory)

function RecentSubjectFactory(factory::F) where { F <: AbstractSubjectFactory }
    return RecentSubjectFactoryInstance(factory)
end

function RecentSubjectFactory(; scheduler::H = AsapScheduler()) where { H <: AbstractScheduler }
    return RecentSubjectFactoryInstance(SubjectFactory{H}(scheduler))
end

##
