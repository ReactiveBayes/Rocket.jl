export SyncActor, sync, SyncActorTimedOutException

import Base: wait

"""
    SyncActor{D, A}(actor::A) where D where A

Sync actor provides a synchronized interface to `wait` for an actor to be notified with a `complete` event.

See also: [`Actor`](@ref), [`sync`](@ref)
"""
mutable struct SyncActor{T, A, W} <: Actor{T}
    completed_condition :: Condition
    is_completed        :: Bool
    is_failed           :: Bool
    actor               :: A

    SyncActor{T, A, W}(actor::A) where { T, A, W } = new(Condition(), false, false, actor)
end

function on_next!(actor::SyncActor{T}, data::T) where T
    next!(actor.actor, data)
end

function on_error!(actor::SyncActor, err)
    actor.is_failed = true
    error!(actor.actor, err)
    notify(actor.completed_condition)
end

function on_complete!(actor::SyncActor)
    actor.is_completed = true
    complete!(actor.actor)
    notify(actor.completed_condition)
end

function Base.wait(actor::SyncActor{T, A, W}) where { T, A, W }
    if !actor.is_failed && !actor.is_completed
        if W > 0
            @async begin
                try
                    sleepfor = W / MILLISECONDS_IN_SECOND
                    sleep(sleepfor)
                    if !actor.is_completed && !actor.is_failed
                        notify(actor.completed_condition, SyncActorTimedOutException(), error = true)
                    end
                catch e
                    println(e)
                end
            end
        end
        wait(actor.completed_condition)
    end
end

struct SyncActorTimedOutException end

mutable struct SyncActorFactoryHandler
    is_completed :: Bool
    actor
end

struct SyncActorFactory{F, W} <: AbstractActorFactory
    factory :: F
    created :: Vector{SyncActorFactoryHandler}

    SyncActorFactory{F, W}(factory::F) where { F <: AbstractActorFactory, W } = new(factory, Vector{SyncActorFactoryHandler}())
end

function create_actor(::Type{L}, factory::SyncActorFactory{F, W}) where { L, F, W }
    actor = sync(create_actor(L, factory.factory), timeout = W)
    push!(factory.created, SyncActorFactoryHandler(false, actor))
    return actor
end

function Base.wait(factory::SyncActorFactory)
    foreach((h) -> begin wait(h.actor); h.is_completed = true end, filter((h) -> !(h.is_completed), factory.created))
end

"""
    sync(actor::A; timeout::Int = -1) where A
    sync(factory::F; timeout::Int = -1) where { F <: AbstractActorFactory }

Creation operator for the `SyncActor` actor.
Accepts optional named `timeout` argument which specifies maximum number of milliseconds to wait (throws SyncActorTimedOutException() on timeout).

# Examples
```jldoctest
using Rocket

actor  = VoidActor{Int}()
synced = sync(actor)
synced isa SyncActor{Int, VoidActor{Int}}

# output
true
```

Can also be used with an `<: AbstractActorFactory` as an argument. In this case `sync` function will return a special actor factory object, which
will store all created actors in array and wrap them with a `sync` function. `wait(sync_factory)` method will wait for all of the created actors to be completed in the order of creation (but only once for each of them).

```jldoctest
using Rocket

values = Int[]

factory  = lambda(on_next = (d) -> push!(values, d))
synced   = sync(factory)

subscribe!(interval(10) |> take(5), synced)

wait(synced)

println(values)

# output
[0, 1, 2, 3, 4]
```

See also: [`SyncActor`](@ref), [`AbstractActor`](@ref)
"""
sync(actor::A; timeout::Int = -1)   where A                             = as_sync(as_actor(A), actor, timeout)
sync(factory::F; timeout::Int = -1) where { F <: AbstractActorFactory } = SyncActorFactory{F, timeout}(factory)

as_sync(::InvalidActorTrait,  actor::A, timeout::Int) where { A }    = throw(InvalidActorTraitUsageError(actor))
as_sync(::ValidActorTrait{D}, actor::A, timeout::Int) where { D, A } = SyncActor{D, A, timeout}(actor)
