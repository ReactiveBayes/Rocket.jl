export SyncActor, sync

import Base: wait

"""
    SyncActor{D, A}(actor::A) where D where A

Sync actor provides a synchronized interface to `wait` for an actor to be notified with a `complete` event.

# Examples

```jldoctest
using Rocket

source = timer(1, 1) |> take(3)
actor  = LoggerActor{Int}()
synced = SyncActor{Int, LoggerActor{Int}}(actor)

subscrption = subscribe!(source, synced)

wait(synced)
;

# output

[LogActor] Data: 0
[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Completed

```

See also: [`Actor`](@ref), [`sync`](@ref)
"""
mutable struct SyncActor{T, A} <: Actor{T}
    completed_condition :: Condition
    is_completed        :: Bool
    is_failed           :: Bool
    actor               :: A

    SyncActor{T, A}(actor::A) where T where A = new(Condition(), false, false, actor)
end

is_exhausted(actor::SyncActor) = actor.is_completed || actor.is_failed || is_exhausted(actor.actor)

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

function Base.wait(actor::SyncActor)
    if !actor.is_failed && !actor.is_completed
        wait(actor.completed_condition)
    end
end

mutable struct SyncActorFactoryHandler
    is_completed :: Bool
    actor
end

struct SyncActorFactory{F} <: AbstractActorFactory
    factory :: F
    created :: Vector{SyncActorFactoryHandler}

    SyncActorFactory{F}(factory::F) where { F <: AbstractActorFactory } = new(factory, Vector{SyncActorFactoryHandler}())
end

function create_actor(::Type{L}, factory::SyncActorFactory) where L
    actor = sync(create_actor(L, factory.factory))
    push!(factory.created, SyncActorFactoryHandler(false, actor))
    return actor
end

function Base.wait(factory::SyncActorFactory)
    foreach((h) -> begin wait(h.actor); h.is_completed = true end, filter((h) -> !(h.is_completed), factory.created))
end

"""
    sync(actor::A) where A
    sync(factory::F) where { F <: AbstractActorFactory }

Creation operator for the `SyncActor` actor.

# Examples
```jldoctest
using Rocket

actor  = LoggerActor{Int}()
synced = sync(actor)
synced isa SyncActor{Int, LoggerActor{Int}}

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
sync(actor::A) where A = as_sync(as_actor(A), actor)
sync(factory::F) where { F <: AbstractActorFactory } = SyncActorFactory{F}(factory)

as_sync(::InvalidActorTrait, actor)                    = throw(InvalidActorTraitUsageError(actor))
as_sync(::ActorTrait{D},     actor::A) where D where A = SyncActor{D, A}(actor)
