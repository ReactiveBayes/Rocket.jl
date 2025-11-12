export Subject, SubjectFactory

import Base: show, similar

##

struct SubjectListener{I}
    schedulerinstance::I
    actor::Any
end

Base.show(io::IO, ::SubjectListener) = print(io, "SubjectListener()")

##

"""
    Subject(::Type{D}; scheduler::H = AsapScheduler())

A Subject is a special type of Observable that allows values to be multicasted to many Observers. Subjects are like EventEmitters.
Every Subject is an Observable and an Actor. You can subscribe to a Subject, and you can call `next!` to feed values as well as `error!` and `complete!`.

Note: By convention, every actor subscribed to a Subject observable is not allowed to throw exceptions during `next!`, `error!` and `complete!` calls. 
Doing so would lead to undefined behaviour. Use `safe()` operator to bypass this rule. 

See also: [`SubjectFactory`](@ref), [`ReplaySubject`](@ref), [`BehaviorSubject`](@ref), [`safe`](@ref)
"""
mutable struct Subject{D,H,I} <: AbstractSubject{D}
    listeners::List{SubjectListener{I}}
    scheduler::H
    isactive::Bool
    iscompleted::Bool
    isfailed::Bool
    lasterror::Any

    Subject{D,H,I}(scheduler::H) where {D,H<:AbstractScheduler,I} =
        new(List(SubjectListener{I}), scheduler, true, false, false, nothing)
end

function Subject(::Type{D}; scheduler::H = AsapScheduler()) where {D,H<:AbstractScheduler}
    return Subject{D,H,instancetype(D, H)}(scheduler)
end

Base.show(io::IO, ::Subject{D,H}) where {D,H} = print(io, "Subject($D, $H)")

Base.similar(subject::Subject{D,H}) where {D,H} =
    Subject(D; scheduler = similar(subject.scheduler))

##

isactive(subject::Subject) = subject.isactive
iscompleted(subject::Subject) = subject.iscompleted
isfailed(subject::Subject) = subject.isfailed
lasterror(subject::Subject) = subject.lasterror

setinactive!(subject::Subject) = subject.isactive = false
setcompleted!(subject::Subject) = subject.iscompleted = true
setfailed!(subject::Subject) = subject.isfailed = true
setlasterror!(subject::Subject, err) = subject.lasterror = err

##

function on_next!(subject::Subject{D,H,I}, data::D) where {D,H,I}
    for listener in subject.listeners
        scheduled_next!(listener.actor, data, listener.schedulerinstance)
    end
end

function on_error!(subject::Subject, err)
    if isactive(subject)
        setinactive!(subject)
        setfailed!(subject)
        setlasterror!(subject, err)
        for listener in subject.listeners
            scheduled_error!(listener.actor, err, listener.schedulerinstance)
        end
        empty!(subject.listeners)
    end
end

function on_complete!(subject::Subject)
    if isactive(subject)
        setinactive!(subject)
        setcompleted!(subject)
        for listener in subject.listeners
            scheduled_complete!(listener.actor, listener.schedulerinstance)
        end
        empty!(subject.listeners)
    end
end

##

function on_subscribe!(subject::Subject{D}, actor) where {D}
    if isfailed(subject)
        error!(actor, lasterror(subject))
        return SubjectSubscription(nothing)
    elseif iscompleted(subject)
        complete!(actor)
        return SubjectSubscription(nothing)
    else
        instance = makeinstance(D, subject.scheduler)
        return scheduled_subscription!(subject, actor, instance)
    end
end

function on_subscribe!(subject::Subject, actor, instance)
    listener = SubjectListener(instance, actor)
    listener_node = pushnode!(subject.listeners, listener)
    return SubjectSubscription(listener_node)
end

##

mutable struct SubjectSubscription <: Teardown
    listener_node::Union{Nothing,ListNode}
end

as_teardown(::Type{<: SubjectSubscription}) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::SubjectSubscription)
    if subscription.listener_node !== nothing
        remove(subscription.listener_node)
        subscription.listener_node = nothing
    end
    return nothing
end

Base.show(io::IO, ::SubjectSubscription) = print(io, "SubjectSubscription()")

##

"""
    SubjectFactory(scheduler::H) where { H <: AbstractScheduler }

A base subject factory that creates an instance of Subject with specified scheduler.

See also: [`AbstractSubjectFactory`](@ref), [`Subject`](@ref)
"""
struct SubjectFactory{H<:AbstractScheduler} <: AbstractSubjectFactory
    scheduler::H
end

create_subject(::Type{L}, factory::SubjectFactory) where {L} =
    Subject(L, scheduler = similar(factory.scheduler))

Base.show(io::IO, ::SubjectFactory{H}) where {H} = print(io, "SubjectFactory($H)")
