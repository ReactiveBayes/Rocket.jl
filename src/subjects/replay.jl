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
struct ReplaySubject{D, S} <: Subscribable{D}
    subject :: S
    buffer  :: CircularBuffer{D}
end

getscheduler(subject::ReplaySubject) = getscheduler(subject.subject)

Base.show(io::IO, ::ReplaySubject{D, S}) where { D, S } = print(io, "ReplaySubject($D, $S)")

Base.similar(subject::ReplaySubject{D, S}) where { D, S } = ReplaySubject(D, capacity(subject.buffer), similar(subject.subject))

ReplaySubject(::Type{D}, size::Int) where D = ReplaySubject(D, size, SubjectFactory(AsapScheduler()))

ReplaySubject(::Type{D}, size::Int, factory::F) where { D, F <: AbstractSubjectFactory } = ReplaySubject(D, size, create_subject(D, factory))
ReplaySubject(::Type{D}, size::Int, subject::S) where { D, S }                           = ReplaySubject{D, S}(subject, CircularBuffer{D}(size))

##

function on_next!(subject::ReplaySubject{D}, data::D) where D
    if isactive(subject.subject)
        push!(subject.buffer, data)
        on_next!(subject.subject, data)
    end
end

on_error!(subject::ReplaySubject, err) = on_error!(subject.subject, err)
on_complete!(subject::ReplaySubject)   = on_complete!(subject.subject)

##

function on_subscribe!(subject::ReplaySubject, actor)
    for value in subject.buffer
        on_next!(actor, value)
    end
    return on_subscribe!(subject.subject, actor)
end

##

"""
    ReplaySubjectFactory(size::Int, factory::F) where { F <: AbstractSubjectFactory }
    ReplaySubjectFactory(size::Int; scheduler::H = AsapScheduler()) where { H  }

A variant of SubjectFactory that creates an instance of ReplaySubject.

See also: [`SubjectFactory`](@ref), [`AbstractSubjectFactory`](@ref), [`ReplaySubject`](@ref), [`Subject`](@ref)
"""
struct ReplaySubjectFactory{ F <: AbstractSubjectFactory } <: AbstractSubjectFactory
    factory :: F
    size    :: Int
end



Base.show(io::IO, subject::ReplaySubjectFactory{F}) where F = print(io, "ReplaySubjectFactory($F, size = $(subject.size))")

create_subject(::Type{L}, factory::ReplaySubjectFactory) where L = ReplaySubject(L, factory.size, factory.factory)

function ReplaySubjectFactory(size::Int, factory::F) where { F <: AbstractSubjectFactory }
    return ReplaySubjectFactory{F}(factory, size)
end

function ReplaySubjectFactory(size::Int; scheduler::H = AsapScheduler()) where { H }
    return ReplaySubjectFactory(size, SubjectFactory{H}(scheduler))
end

##
