export Subject

import Base: show

##

struct SubjectListener{I}
    schedulerinstance :: I
    actor
end

Base.show(io::IO, ::Type{ <: SubjectListener }) = print(io, "SubjectListener")
Base.show(io::IO, ::SubjectListener)            = print(io, "SubjectListener()")

mutable struct SubjectProps
    iscompleted :: Bool
    isfailed    :: Bool
    lasterror   :: Any

    SubjectProps() = new(false, false, nothing)
end

Base.show(io::IO, ::Type{ <: SubjectProps }) = print(io, "SubjectProps")
Base.show(io::IO, ::SubjectProps)            = print(io, "SubjectProps()")

##

struct Subject{D, H, I} <: Actor{D}
    listeners :: Vector{SubjectListener{I}}
    props     :: SubjectProps
    scheduler :: H

    Subject{D, H, I}(scheduler::H) where { D, H, I } = new(Vector{SubjectListener{I}}(), SubjectProps(), scheduler)
end

function Subject(::Type{D}; scheduler::H = AsapScheduler()) where { D, H }
    return Subject{D, H, instancetype(D, H)}(scheduler)
end

as_subject(::Type{ <: Subject{D} })      where D = ValidSubject{D}()
as_subscribable(::Type{ <: Subject{D} }) where D = SimpleSubscribableTrait{D}()

Base.show(io::IO, ::Type{ <: Subject{ D, H }}) where { D, H } = print(io, "Subject{$D, $H}")
Base.show(io::IO, ::Subject{D, H})             where { D, H } = print(io, "Subject($D, $H)")

##

iscompleted(subject::Subject) = subject.props.iscompleted
isfailed(subject::Subject)    = subject.props.isfailed
lasterror(subject::Subject)   = subject.props.lasterror

setcompleted!(subject::Subject)      = subject.props.iscompleted = true
setfailed!(subject::Subject)         = subject.props.isfailed = true
setlasterror!(subject::Subject, err) = subject.props.lasterror = err

##

function on_next!(subject::Subject{D}, data::D) where D
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
                failedlisteners = similar(listeners)
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

function on_subscribe!(subject::Subject{D, H, I}, actor) where { D, H, I }
    if isfailed(subject)
        error!(actor, lasterror(subject))
        return VoidTeardown()
    elseif iscompleted(subject)
        complete!(actor)
        return VoidTeardown()
    else
        instance = makeinstance(D, subject.scheduler)
        return scheduled_subscription!(subject, actor, instance)
    end
end

function on_subscribe!(subject::Subject{D, H, I}, actor, instance) where { D, H, I }
    listener = SubjectListener{I}(instance, actor)
    push!(subject.listeners, listener)
    return SubjectSubscription(subject, listener)
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

Base.show(io::IO, ::Type{ <: SubjectSubscription }) where { D, H } = print(io, "SubjectSubscription")
Base.show(io::IO, ::SubjectSubscription)            where { D, H } = print(io, "SubjectSubscription()")

##

struct SubjectFactory{H} <: AbstractSubjectFactory
    scheduler :: H
end

create_subject(::Type{L}, factory::SubjectFactory) where L = Subject(L, scheduler = similar(factory.scheduler))

Base.show(io::IO, ::Type{ <: SubjectFactory{H} }) where { H } = print(io, "SubjectFactory{$H}")
Base.show(io::IO, ::SubjectFactory{H})            where { H } = print(io, "SubjectFactory($H)")
