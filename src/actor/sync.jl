export SyncActor
export on_next!, on_error!, on_complete!, is_exhausted
export sync

import Base: wait

"""
    SyncActor{D}() where D

Sync actor provides a synchronized interface to `wait` for an actor be notified with a `complete` event.

See also: [`Actor`](@ref)
"""
mutable struct SyncActor{T} <: Actor{T}
    completed_condition :: Condition
    is_completed        :: Bool
    is_failed           :: Bool
    actor

    SyncActor{T}(actor) where T = new(Condition(), false, false, actor)
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
    sync(actor)

Helper function to create an SyncActor

See also: [`SyncActor`](@ref), [`AbstractActor`](@ref)
"""
sync(actor::A) where A = as_sync(as_actor(A), actor)

as_sync(::UndefinedActorTrait, actor)         = throw(UndefinedActorTraitUsageError(actor))
as_sync(::ActorTrait{D},       actor) where D = SyncActor{D}(actor)
