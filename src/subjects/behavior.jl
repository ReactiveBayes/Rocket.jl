export BehaviorSubject, BehaviorSubjectFactory

import Base: show

"""
    BehaviorSubject(value::D) where D
    BehaviorSubject(::Type{D}, value) where D
    BehaviorSubject(::Type{D}, value, factory::F) where { D, F <: AbstractSubjectFactory }
    BehaviorSubject(::Type{D}, value, subject::S) where { D, S }

A variant of Subject that requires an initial value and emits its current value whenever it is subscribed to.

See also: [`BehaviorSubjectFactory`](@ref), [`Subject`](@ref), [`SubjectFactory`](@ref)
"""
function BehaviorSubject end

"""
    BehaviorSubjectFactory(default, factory::F) where { F <: AbstractSubjectFactory }
    BehaviorSubjectFactory(default; scheduler::H = AsapScheduler()) where { H <: AbstractScheduler }

A variant of SubjectFactory that creates an instance of ReplaySubject.

See also: [`SubjectFactory`](@ref), [`AbstractSubjectFactory`](@ref), [`BehaviorSubject`](@ref), [`Subject`](@ref)
"""
function BehaviorSubjectFactory end

mutable struct BehaviourSubjectProps{D}
    current :: D
end

Base.show(io::IO, ::BehaviourSubjectProps) = print(io, "BehaviourSubjectProps()")

##

struct BehaviorSubjectInstance{D, S} <: AbstractSubject{D}
    subject :: S
    props   :: BehaviourSubjectProps{D}
end

Base.show(io::IO, ::BehaviorSubjectInstance{D, S}) where { D, S } = print(io, "BehaviorSubject($D, $S)")

function BehaviorSubject(value::D) where D
    return BehaviorSubject(D, value, SubjectFactory(AsapScheduler()))
end

function BehaviorSubject(::Type{D}, value) where D
    return BehaviorSubject(D, value, SubjectFactory(AsapScheduler()))
end

function BehaviorSubject(::Type{D}, value, factory::F) where { D, F <: AbstractSubjectFactory }
    return BehaviorSubject(D, value, create_subject(D, factory))
end

function BehaviorSubject(::Type{D}, value, subject::S) where { D, S }
    return as_behavior_subject(D, as_subject(S), convert(D, value), subject)
end

as_behavior_subject(::Type{D},  ::InvalidSubjectTrait,    current,     subject)    where D          = throw(InvalidSubjectTraitUsageError(subject))
as_behavior_subject(::Type{D1}, ::ValidSubjectTrait{D2},  current,     subject)    where { D1, D2 } = throw(InconsistentSubjectDataTypesError{D1, D2}(subject))
as_behavior_subject(::Type{D},  ::ValidSubjectTrait{D},   current::D,  subject::S) where { D, S }   = BehaviorSubjectInstance{D, S}(subject, BehaviourSubjectProps{D}(current))

##

getcurrent(subject::BehaviorSubjectInstance)         = subject.props.current
setcurrent!(subject::BehaviorSubjectInstance, value) = subject.props.current = value

##

function on_next!(subject::BehaviorSubjectInstance{D}, data::D) where D
    setcurrent!(subject, data)
    next!(subject.subject, data)
end

function on_error!(subject::BehaviorSubjectInstance, err)
    error!(subject.subject, err)
end

function on_complete!(subject::BehaviorSubjectInstance)
    complete!(subject.subject)
end

##

function on_subscribe!(subject::BehaviorSubjectInstance, actor)
    next!(actor, getcurrent(subject))
    return subscribe!(subject.subject, actor)
end

##

struct BehaviorSubjectFactoryInstance{ F <: AbstractSubjectFactory } <: AbstractSubjectFactory
    factory :: F
    default
end

Base.show(io::IO, subject::BehaviorSubjectFactoryInstance{F}) where F = print(io, "BehaviorSubjectFactory($F, default = $(subject.default))")

create_subject(::Type{L}, factory::BehaviorSubjectFactoryInstance) where L = BehaviorSubject(L, convert(L, factory.default), factory.factory)

function BehaviorSubjectFactory(default, factory::F) where { F <: AbstractSubjectFactory }
    return BehaviorSubjectFactoryInstance(factory, default)
end

function BehaviorSubjectFactory(default; scheduler::H = AsapScheduler()) where { H <: AbstractScheduler }
    return BehaviorSubjectFactoryInstance(SubjectFactory{H}(scheduler), default)
end

##
