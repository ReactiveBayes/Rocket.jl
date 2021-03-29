export ReplaySubject, ReplaySubjectFactory

import DataStructures: CircularBuffer, capacity
import Base: show, similar

"""
    ReplaySubject(::Type{D}, size::Int) where D
    ReplaySubject(::Type{D}, size::Int, factory::F) where { D, F <: AbstractSubjectFactory }
    ReplaySubject(::Type{D}, size::Int, subject::S) where { D, S }

A variant of Subject that "replays" or emits old values to new subscribers.
It buffers a set number of values and will emit those values immediately to any new subscribers
in addition to emitting new values to existing subscribers.

See also: [`ReplaySubjectFactory`](@ref), [`Subject`](@ref), [`SubjectFactory`](@ref)
"""
function ReplaySubject end

"""
    ReplaySubjectFactory(size::Int, factory::F) where { F <: AbstractSubjectFactory }
    ReplaySubjectFactory(size::Int; scheduler::H = AsapScheduler()) where { H <: AbstractScheduler }

A variant of SubjectFactory that creates an instance of ReplaySubject.

See also: [`SubjectFactory`](@ref), [`AbstractSubjectFactory`](@ref), [`ReplaySubject`](@ref), [`Subject`](@ref)
"""
function ReplaySubjectFactory end

struct ReplaySubjectInstance{D, S} <: AbstractSubject{D}
    subject :: S
    buffer  :: CircularBuffer{D}
end

Base.show(io::IO, ::ReplaySubjectInstance{D, S}) where { D, S } = print(io, "ReplaySubjectInstance($D, $S)")

Base.similar(subject::ReplaySubjectInstance{D, S}) where { D, S } = ReplaySubject(D, capacity(subject.buffer), similar(subject.subject))

function ReplaySubject(::Type{D}, size::Int) where D
    return ReplaySubject(D, size, SubjectFactory(AsapScheduler()))
end

function ReplaySubject(::Type{D}, size::Int, factory::F) where { D, F <: AbstractSubjectFactory }
    return ReplaySubject(D, size, create_subject(D, factory))
end

function ReplaySubject(::Type{D}, size::Int, subject::S) where { D, S }
    return as_replay_subject(D, as_subject(S), size, subject)
end

as_replay_subject(::Type{D},  ::InvalidSubjectTrait,    size::Int, subject)    where D          = throw(InvalidSubjectTraitUsageError(subject))
as_replay_subject(::Type{D1}, ::ValidSubjectTrait{D2},  size::Int, subject)    where { D1, D2 } = throw(InconsistentSubjectDataTypesError{D1, D2}(subject))
as_replay_subject(::Type{D},  ::ValidSubjectTrait{D},   size::Int, subject::S) where { D, S }   = ReplaySubjectInstance{D, S}(subject, CircularBuffer{D}(size))

##

function on_next!(subject::ReplaySubjectInstance{D}, data::D) where D
    if isactive(subject.subject)
        push!(subject.buffer, data)
        next!(subject.subject, data)
    end
end

function on_error!(subject::ReplaySubjectInstance, err)
    error!(subject.subject, err)
end

function on_complete!(subject::ReplaySubjectInstance)
    complete!(subject.subject)
end

##

function on_subscribe!(subject::ReplaySubjectInstance, actor)
    for value in subject.buffer
        next!(actor, value)
    end
    return subscribe!(subject.subject, actor)
end

##

struct ReplaySubjectFactoryInstance{ F <: AbstractSubjectFactory } <: AbstractSubjectFactory
    factory :: F
    size    :: Int
end

Base.show(io::IO, subject::ReplaySubjectFactoryInstance{F}) where F = print(io, "ReplaySubjectFactoryInstance($F, size = $(subject.size))")

create_subject(::Type{L}, factory::ReplaySubjectFactoryInstance) where L = ReplaySubject(L, factory.size, factory.factory)

function ReplaySubjectFactory(size::Int, factory::F) where { F <: AbstractSubjectFactory }
    return ReplaySubjectFactoryInstance(factory, size)
end

function ReplaySubjectFactory(size::Int; scheduler::H = AsapScheduler()) where { H <: AbstractScheduler }
    return ReplaySubjectFactoryInstance(SubjectFactory{H}(scheduler), size)
end

##
