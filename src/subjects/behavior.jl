export BehaviorSubject, BehaviorSubjectFactory

import Base: show

# TODO: docs

##

mutable struct BehaviourSubjectProps{D}
    current :: D
end

Base.show(io::IO, ::Type{ <: BehaviourSubjectProps }) = print(io, "BehaviourSubjectProps")
Base.show(io::IO, ::BehaviourSubjectProps)            = print(io, "BehaviourSubjectProps()")

##

"""
    BehaviorSubjectInstance

A variant of Subject that requires an initial value and emits its current value whenever it is subscribed to.

# Arguments
- `current`: Default current value
- `subject`: Subject base type

See also: [`make_behavior_subject`](@ref), [`make_subject`](@ref)
"""
struct BehaviorSubjectInstance{D, S} <: Actor{D}
    subject :: S
    props   :: BehaviourSubjectProps{D}
end

Base.show(io::IO, ::Type{ <: BehaviorSubjectInstance{D, S} }) where { D, S } = print(io, "BehaviorSubject{$D, $S}")
Base.show(io::IO, ::BehaviorSubjectInstance{D, S})            where { D, S } = print(io, "BehaviorSubject($D, $S)")

function BehaviorSubject(value::D) where { D, H }
    return BehaviorSubject(D, value, SubjectFactory(AsapScheduler()))
end

function BehaviorSubject(::Type{D}, value) where { D }
    return BehaviorSubject(D, value, SubjectFactory(AsapScheduler()))
end

function BehaviorSubject(::Type{D}, value, factory::F) where { D, F <: AbstractSubjectFactory }
    return BehaviorSubject(D, value, create_subject(D, factory))
end

function BehaviorSubject(::Type{D}, value, subject::S) where { D, S }
    return as_behavior_subject(D, as_subject(S), convert(D, value), subject)
end

as_behavior_subject(::Type{D},  ::InvalidSubject,    current,     subject)    where D          = throw(InvalidSubjectTraitUsageError(subject))
as_behavior_subject(::Type{D1}, ::ValidSubject{D2},  current,     subject)    where { D1, D2 } = throw(InconsistentSubjectDataTypesError{D1, D2}(subject))
as_behavior_subject(::Type{D},  ::ValidSubject{D},   current::D,  subject::S) where { D, S }   = BehaviorSubjectInstance{D, S}(subject, BehaviourSubjectProps{D}(current))

as_subject(::Type{<:BehaviorSubjectInstance{D}})      where D = ValidSubject{D}()
as_subscribable(::Type{<:BehaviorSubjectInstance{D}}) where D = SimpleSubscribableTrait{D}()

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

Base.show(io::IO, ::Type{ <: BehaviorSubjectFactoryInstance{F} }) where F = print(io, "BehaviorSubjectFactory{$F}(default = $(subject.default))")
Base.show(io::IO, subject::BehaviorSubjectFactoryInstance{F})     where F = print(io, "BehaviorSubjectFactory($F, default = $(subject.default))")

create_subject(::Type{L}, factory::BehaviorSubjectFactoryInstance) where L = BehaviourSubject(L, convert(L, factory.default), factory.factory)

function BehaviorSubjectFactory(default, factory::F) where { F <: AbstractSubjectFactory }
    return BehaviorSubjectFactoryInstance(factory, default)
end

function BehaviorSubjectFactory(default; scheduler::H = AsapScheduler()) where H
    return BehaviorSubjectFactoryInstance(SubjectFactory{H}(scheduler), default)
end

##
