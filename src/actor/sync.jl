export SyncActor
export on_next!, on_error!, on_complete!, is_exhausted
export sync

import Base: wait

"""
    SyncActor{D, A}(actor::A) where D where A

Sync actor provides a synchronized interface to `wait` for an actor to be notified with a `complete` event.

# Examples

```jldoctest
using Rx

source = timer(0, 1) |> take(3)
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

"""
    sync(actor::A) where A

Creation operator for the `SyncActor` actor.

# Examples
```jldoctest
using Rx

actor  = LoggerActor{Int}()
synced = sync(actor)
synced isa SyncActor{Int, LoggerActor{Int}}

# output
true

```

See also: [`SyncActor`](@ref), [`AbstractActor`](@ref)
"""
sync(actor::A) where A = as_sync(as_actor(A), actor)

as_sync(::InvalidActorTrait, actor)                    = throw(InvalidActorTraitUsageError(actor))
as_sync(::ActorTrait{D},     actor::A) where D where A = SyncActor{D, A}(actor)
