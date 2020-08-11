export Subject, SubjectFactory

import Base: show

##

struct SubjectListener{I}
    schedulerinstance :: I
    actor
end

Base.show(io::IO, ::SubjectListener) = print(io, "SubjectListener()")

mutable struct SubjectProps
    iscompleted :: Bool
    isfailed    :: Bool
    lasterror   :: Any

    SubjectProps() = new(false, false, nothing)
end

Base.show(io::IO, ::SubjectProps) = print(io, "SubjectProps()")

##

"""
    Subject(::Type{D}; scheduler::H = AsapScheduler())

A Subject is a special type of Observable that allows values to be multicasted to many Observers. Subjects are like EventEmitters.
Every Subject is an Observable and an Actor. You can subscribe to a Subject, and you can call `next!` to feed values as well as `error!` and `complete!`.

See also: [`SubjectFactory`](@ref), [`ReplaySubject`](@ref), [`BehaviorSubject`](@ref)
"""
struct Subject{D, H, I} <: AbstractSubject{D}
    listeners :: Vector{SubjectListener{I}}
    props     :: SubjectProps
    scheduler :: H

    Subject{D, H, I}(scheduler::H) where { D, H <: AbstractScheduler, I } = new(Vector{SubjectListener{I}}(), SubjectProps(), scheduler)
end

function Subject(::Type{D}; scheduler::H = AsapScheduler()) where { D, H <: AbstractScheduler }
    return Subject{D, H, instancetype(D, H)}(scheduler)
end

Base.show(io::IO, ::Subject{D, H}) where { D, H } = print(io, "Subject($D, $H)")

##

iscompleted(subject::Subject) = subject.props.iscompleted
isfailed(subject::Subject)    = subject.props.isfailed
lasterror(subject::Subject)   = subject.props.lasterror

setcompleted!(subject::Subject)      = subject.props.iscompleted = true
setfailed!(subject::Subject)         = subject.props.isfailed = true
setlasterror!(subject::Subject, err) = subject.props.lasterror = err

##

function on_next!(subject::Subject{D, H, I}, data::D) where { D, H, I }
    failedlisteners = nothing
    listeners       = copy(subject.listeners)

    for listener in listeners
        try
            next!(listener.actor, data, listener.schedulerinstance)
        catch exception
            @warn "An exception occured during next! invocation in subject $(subject) for actor $(listener.actor). Cannot deliver data $(data)"
            @warn exception
            error!(listener.actor, exception, listener.schedulerinstance)
            if failedlisteners === nothing
                failedlisteners = Vector{SubjectListener{I}}()
            end
            push!(failedlisteners, listener)
        end
    end

    if failedlisteners !== nothing
        unsubscribe_listeners!(subject, failedlisteners)
    end
end

function on_error!(subject::Subject, err)
    if !iscompleted(subject) && !isfailed(subject)
        setfailed!(subject)
        setlasterror!(subject, err)

        listeners = copy(subject.listeners)

        for listener in listeners
            try
                error!(listener.actor, err, listener.schedulerinstance)
            catch exception
                @warn "An exception occured during error! invocation in subject $(subject) for actor $(listener.actor). Cannot deliver error $(error)"
                @warn exception
            end
        end

        unsubscribe_listeners!(subject, subject.listeners)
    end
end

function on_complete!(subject::Subject)
    if !iscompleted(subject) && !isfailed(subject)
        setcompleted!(subject)

        listeners = copy(subject.listeners)

        for listener in listeners
            try
                complete!(listener.actor, listener.schedulerinstance)
            catch exception
                @warn "An exception occured during complete! invocation in subject $(subject) for actor $(listener.actor)."
                @warn exception
            end
        end

        unsubscribe_listeners!(subject, subject.listeners)
    end
end

function unsubscribe_listeners!(subject::Subject, listeners)
    foreach((listener) -> unsubscribe!(SubjectSubscription(subject, listener)), copy(listeners))
end

##

function on_subscribe!(subject::Subject{D}, actor) where { D }
    if isfailed(subject)
        error!(actor, lasterror(subject))
        return voidTeardown
    elseif iscompleted(subject)
        complete!(actor)
        return voidTeardown
    else
        instance = makeinstance(D, subject.scheduler)
        listener = SubjectListener(instance, actor)
        push!(subject.listeners, listener)
        return SubjectSubscription(subject, listener)
    end
end


##

struct SubjectSubscription{ S, L } <: Teardown
    subject  :: S
    listener :: L
end

as_teardown(::Type{ <: SubjectSubscription }) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::SubjectSubscription)
    filter!((listener) -> listener !== subscription.listener, subscription.subject.listeners)
    return nothing
end

Base.show(io::IO, ::SubjectSubscription) = print(io, "SubjectSubscription()")

##

"""
    SubjectFactory(scheduler::H) where { H <: AbstractScheduler }

A base subject factory that creates an instance of Subject with specified scheduler.

See also: [`AbstractSubjectFactory`](@ref), [`Subject`](@ref)
"""
struct SubjectFactory{ H <: AbstractScheduler } <: AbstractSubjectFactory
    scheduler :: H
end

create_subject(::Type{L}, factory::SubjectFactory) where L = Subject(L, scheduler = similar(factory.scheduler))

Base.show(io::IO, ::SubjectFactory{H}) where H = print(io, "SubjectFactory($H)")
