export Subject, SubjectFactory

import Base: show, similar

##

"""
    Subject(::Type{D}; scheduler::H = AsapScheduler())

A Subject is a special type of Observable that allows values to be multicasted to many Observers. Subjects are like EventEmitters.
Every Subject is an Observable and an Actor. You can subscribe to a Subject, and you can call `next!` to feed values as well as `error!` and `complete!`.

Note: By convention, every actor subscribed to a Subject observable is not allowed to throw exceptions during `next!`, `error!` and `complete!` calls. 
Doing so would lead to undefined behaviour. Use `safe()` operator to bypass this rule. 

See also: [`ReplaySubject`](@ref), [`BehaviorSubject`](@ref), [`safe`](@ref)
"""
mutable struct Subject{D, H} <: Subscribable{D}
    scheduler   :: H
    actors      :: List{Any}
    isactive    :: Bool
    iscompleted :: Bool
    isfailed    :: Bool
    lasterror   :: Any

    Subject{D, H}(scheduler::H) where { D, H } = new(scheduler, List(Any), true, false, false, nothing)
end

function Subject(::Type{D}; scheduler::H = AsapScheduler()) where { D, H }
    return Subject{D, H}(scheduler)
end

Base.show(io::IO, ::Subject{D, H}) where { D, H } = print(io, "Subject($D, $H)")

Base.similar(subject::Subject{D, H}) where { D, H } = Subject(D; scheduler = similar(subject.scheduler))

##

getscheduler(subject::Subject) = subject.scheduler

isactive(subject::Subject)    = subject.isactive
iscompleted(subject::Subject) = subject.iscompleted
isfailed(subject::Subject)    = subject.isfailed
lasterror(subject::Subject)   = subject.lasterror

setinactive!(subject::Subject)       = subject.isactive    = false
setcompleted!(subject::Subject)      = subject.iscompleted = true
setfailed!(subject::Subject)         = subject.isfailed    = true
setlasterror!(subject::Subject, err) = subject.lasterror   = err

##

on_next!(subject::Subject{D}, data::L) where { D, L } = error("$(subject) expects data of type $(D), but $(L) have been passed.")

function on_next!(subject::Subject{D}, data::D) where { D }
    scheduler = getscheduler(subject)
    for actor in subject.actors
        next!(scheduler, actor, data)
    end
end

function on_error!(subject::Subject, err)
    if isactive(subject)
        setinactive!(subject)
        setfailed!(subject)
        setlasterror!(subject, err)
        scheduler = getscheduler(subject)
        for actor in subject.actors
            error!(scheduler, actor, err)
        end
        empty!(subject.listeners)
    end
end

function on_complete!(subject::Subject)
    if isactive(subject)
        setinactive!(subject)
        setcompleted!(subject)
        scheduler = getscheduler(subject)
        for actor in subject.actors
            complete!(scheduler, actor)
        end
        empty!(subject.listeners)
    end
end

##

function on_subscribe!(subject::Subject{D}, actor) where { D }
    scheduler = getscheduler(subject)
    if isfailed(subject)
        error!(scheduler, actor, lasterror(subject))
        return SubjectSubscription(nothing)
    elseif iscompleted(subject)
        complete!(scheduler, actor)
        return SubjectSubscription(nothing)
    else
        actor_node = pushnode!(subject.actors, actor)
        return SubjectSubscription(actor_node)
    end
end

##

mutable struct SubjectSubscription <: Subscription
    actor_node :: Union{Nothing, ListNode}
end

function on_unsubscribe!(subscription::SubjectSubscription)
    if subscription.actor_node !== nothing
        remove(subscription.actor_node)
        subscription.actor_node = nothing
    end
    return nothing
end

Base.show(io::IO, ::SubjectSubscription) = print(io, "SubjectSubscription()")

##

"""
    SubjectFactory(scheduler::H) where { H }

A base subject factory that creates an instance of Subject with specified scheduler.

See also: [`AbstractSubjectFactory`](@ref), [`Subject`](@ref)
"""
struct SubjectFactory{H} <: AbstractSubjectFactory
    scheduler :: H
end

create_subject(::Type{L}, factory::SubjectFactory) where L = Subject(L, scheduler = similar(factory.scheduler))

Base.show(io::IO, ::SubjectFactory{H}) where H = print(io, "SubjectFactory($H)")
