export BehaviorSubject, BehaviorSubjectFactory

import Base: show, similar

"""
    BehaviorSubject(value::D) where D
    BehaviorSubject(::Type{D}, value) where D
    BehaviorSubject(::Type{D}, value, factory::F) where { D, F <: AbstractSubjectFactory }
    BehaviorSubject(::Type{D}, value, subject::S) where { D, S }

A variant of Subject that requires an initial value and emits its current value whenever it is subscribed to.

See also: [`BehaviorSubjectFactory`](@ref), [`Subject`](@ref), [`AbstractSubjectFactory`](@ref)
"""
mutable struct BehaviorSubject{D, S} <: Subscribable{D}
    subject :: S
    current :: D
end

##

getscheduler(subject::BehaviorSubject) = getscheduler(subject.subject)

Base.show(io::IO, ::BehaviorSubject{D, S}) where { D, S } = print(io, "BehaviorSubject($D, $S)")

Base.similar(subject::BehaviorSubject{D, S}) where { D, S } = BehaviorSubject(D, getcurrent(subject), similar(subject.subject))

BehaviorSubject(value::D)         where D = BehaviorSubject(D, value, SubjectFactory(AsapScheduler()))
BehaviorSubject(::Type{D}, value) where D = BehaviorSubject(D, value, SubjectFactory(AsapScheduler()))

BehaviorSubject(::Type{D}, value, factory::F) where { D, F <: AbstractSubjectFactory } = BehaviorSubject(D, value, create_subject(D, factory))
BehaviorSubject(::Type{D}, value, subject::S) where { D, S }                           = BehaviorSubject{D, S}(subject, convert(D, value))

##

getcurrent(subject::BehaviorSubject)         = subject.current
setcurrent!(subject::BehaviorSubject, value) = subject.current = value

##

function on_next!(subject::BehaviorSubject{D}, data::D) where D
    if isactive(subject.subject)
        setcurrent!(subject, data)
        on_next!(subject.subject, data)
    end
end

on_error!(subject::BehaviorSubject, err) = on_error!(subject.subject, err)
on_complete!(subject::BehaviorSubject)   = on_complete!(subject.subject)

##

function on_subscribe!(subject::BehaviorSubject, actor)
    on_next!(actor, getcurrent(subject))
    return on_subscribe!(subject.subject, actor)
end

##

"""
    BehaviorSubjectFactory(default::D, factory::F)                     where { F <: AbstractSubjectFactory }
    BehaviorSubjectFactory(default::D; scheduler::H = AsapScheduler()) where { H <: AbstractScheduler }

A variant of SubjectFactory that creates an instance of ReplaySubject.

See also: [`SubjectFactory`](@ref), [`AbstractSubjectFactory`](@ref), [`BehaviorSubject`](@ref), [`Subject`](@ref)
"""
struct BehaviorSubjectFactory{ D, F <: AbstractSubjectFactory } <: AbstractSubjectFactory
    default :: D
    factory :: F
end

Base.show(io::IO, subject::BehaviorSubjectFactory{D, F}) where { D, F } = print(io, "BehaviorSubjectFactory(default = $(subject.default), $F)")

create_subject(::Type{L}, factory::BehaviorSubjectFactory) where L = BehaviorSubject(L, convert(L, factory.default), factory.factory)

function BehaviorSubjectFactory(default::D; scheduler::H = AsapScheduler()) where { D, H }
    return BehaviorSubjectFactory(default, SubjectFactory{H}(scheduler))
end

##
