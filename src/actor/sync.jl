export SyncActor, sync, SyncActorTimedOutException

import Base: show, showerror, wait, lock, unlock, notify

mutable struct SyncActorProps
    iscompleted::Bool
    isfailed::Bool
end

"""
    SyncActor{T, A}(actor::A; withlock::Bool = true, timeout::Int = -1) where { T, A }

Sync actor provides a synchronized interface to `wait` for an actor to be notified with a `complete` event.
By default creates a re-entrant lock for synchronizing `next!`, `error!` and `complete!` events.

See also: [`Actor`](@ref), [`sync`](@ref)
"""
struct SyncActor{T,A} <: Actor{T}
    lock::ReentrantLock
    condition::Condition
    actor::A
    props::SyncActorProps
    withlock::Bool
    timeout::Int

    SyncActor{T,A}(actor::A; withlock::Bool = true, timeout::Int = -1) where {T,A} = begin
        return new(
            ReentrantLock(),
            Condition(),
            actor,
            SyncActorProps(false, false),
            withlock,
            timeout,
        )
    end
end

Base.show(io::IO, actor::SyncActor{T,A}) where {T,A} = print(io, "SyncActor($A)")

iswithlock(actor::SyncActor) = actor.withlock

Base.lock(actor::SyncActor) = lock(actor.lock)
Base.unlock(actor::SyncActor) = unlock(actor.lock)

iscompleted(actor::SyncActor) = actor.props.iscompleted
isfailed(actor::SyncActor) = actor.props.isfailed

setcompleted!(actor::SyncActor) = actor.props.iscompleted = true
setfailed!(actor::SyncActor) = actor.props.isfailed = true

Base.notify(actor::SyncActor) = notify(getcondition(actor))

getcondition(actor::SyncActor) = actor.condition
gettimeout(actor::SyncActor) = actor.timeout

macro check_lock(expr)
    output = quote
        if iswithlock(actor)
            lock(actor)
        end
        $(expr)
        if iswithlock(actor)
            unlock(actor)
        end
    end
    return esc(output)
end

function on_next!(actor::SyncActor{T}, data::T) where {T}
    @check_lock begin
        next!(actor.actor, data)
    end
end

function on_error!(actor::SyncActor, err)
    @check_lock begin
        setfailed!(actor)
        error!(actor.actor, err)
        notify(actor)
    end
end

function on_complete!(actor::SyncActor)
    @check_lock begin
        setcompleted!(actor)
        complete!(actor.actor)
        notify(actor)
    end
end

function Base.wait(actor::SyncActor)
    if !isfailed(actor) && !iscompleted(actor)
        timeout = gettimeout(actor) / MILLISECONDS_IN_SECOND
        if timeout >= 0.001
            @async begin
                try
                    sleep(timeout)
                    if !isfailed(actor) && !iscompleted(actor)
                        notify(
                            getcondition(actor),
                            SyncActorTimedOutException(),
                            error = true,
                        )
                    end
                catch exception
                    @warn "Exception in Base.wait(actor::SyncActor): $exception"
                end
            end
        end
        wait(getcondition(actor))
    end
end

struct SyncActorTimedOutException <: Exception end

mutable struct SyncActorFactoryProps
    actors::Vector{SyncActor}
end

struct SyncActorFactory{F} <: AbstractActorFactory
    factory::F
    withlock::Bool
    timeout::Int
    props::SyncActorFactoryProps

    SyncActorFactory{F}(
        factory::F;
        withlock::Bool = true,
        timeout::Int = -1,
    ) where {F<:AbstractActorFactory} = begin
        return new(factory, withlock, timeout, SyncActorFactoryProps(Vector{SyncActor}()))
    end
end

function create_actor(::Type{L}, factory::SyncActorFactory{F}) where {L,F}
    actor = sync(
        create_actor(L, factory.factory),
        withlock = factory.withlock,
        timeout = factory.timeout,
    )
    push!(factory.props.actors, actor)
    return actor
end

function Base.wait(factory::SyncActorFactory)
    foreach(wait, factory.props.actors)
    factory.props.actors = Vector{SyncActor}()
end

"""
    sync(actor::A; withlock::Bool = true, timeout::Int = -1) where A
    sync(factory::F; withlock::Bool = true, timeout::Int = -1) where { F <: AbstractActorFactory }

Creation operator for the `SyncActor` actor.
Accepts optional named `timeout` argument which specifies maximum number of milliseconds to wait (throws SyncActorTimedOutException() on timeout).
Also accepts optional `withlock` boolean flag indicating that every `next!`, `error!` and `complete!` event should be guarded with `ReentrantLock`.

# Examples
```
using Rocket

actor  = keep(Int)
synced = sync(actor)

subscribe!(from(0:5, scheduler = AsyncScheduler()), synced)

yield()

wait(synced)
show(synced.actor.values)

# output
[0, 1, 2, 3, 4, 5]
```

Can also be used with an `<: AbstractActorFactory` as an argument. In this case `sync` function will return a special actor factory object, which
will store all created actors in array and wrap them with a `sync` function. `wait(sync_factory)` method will wait for all of the created actors to be completed in the order of creation (but only once for each of them).

```
using Rocket

values = Int[]

factory  = lambda(on_next = (d) -> push!(values, d))
synced   = sync(factory)

subscribe!(from(0:5, scheduler = AsyncScheduler()), synced)

yield()

wait(synced)
show(values)

# output
[0, 1, 2, 3, 4, 5]
```

See also: [`SyncActor`](@ref), [`AbstractActor`](@ref)
"""
sync(actor::A; withlock::Bool = true, timeout::Int = -1) where {A} =
    as_sync(as_actor(A), actor, withlock, timeout)
sync(factory::F; withlock::Bool = true, timeout::Int = -1) where {F<:AbstractActorFactory} =
    SyncActorFactory{F}(factory; withlock = withlock, timeout = timeout)

as_sync(::InvalidActorTrait, actor::A, withlock::Bool, timeout::Int) where {A} =
    throw(InvalidActorTraitUsageError(actor))
as_sync(::BaseActorTrait{D}, actor::A, withlock::Bool, timeout::Int) where {D,A} =
    SyncActor{D,A}(actor; withlock = withlock, timeout = timeout)
as_sync(::NextActorTrait{D}, actor::A, withlock::Bool, timeout::Int) where {D,A} =
    SyncActor{D,A}(actor; withlock = withlock, timeout = timeout)
as_sync(::ErrorActorTrait{D}, actor::A, withlock::Bool, timeout::Int) where {D,A} =
    SyncActor{D,A}(actor; withlock = withlock, timeout = timeout)
as_sync(::CompletionActorTrait{D}, actor::A, withlock::Bool, timeout::Int) where {D,A} =
    SyncActor{D,A}(actor; withlock = withlock, timeout = timeout)
