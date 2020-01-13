export AsyncActor, async
export on_next!, on_error!, on_complete!
export close

import Base: close

"""
    AsyncActor{D}(actor) where D

AsyncActor wraps an actor and send a data from a stream to this actor asynchronously in a different `Task`.
You have to `close` this actor when you do not need it.

# Constructor arguments
- `actor`: any actor to be wrapped

See also: [`Actor`](@ref), [`async`](@ref)
"""
struct AsyncActor{D} <: Actor{D}
    channel :: Channel{D}
    actor

    AsyncActor{D}(actor) where D = begin
        channel = Channel{D}(Inf, spawn = true) do ch
            while true
                message = take!(ch)
                next!(actor, message)
            end
        end
        new(channel, actor)
    end
end

function on_next!(actor::AsyncActor{D}, data::D) where D
    put!(actor.channel, data)
end

on_error!(actor::AsyncActor, err) = error!(actor.actor, err)
on_complete!(actor::AsyncActor)   = complete!(actor.actor)

"""
    async(actor)

Helper function to create an AsyncActor

See also: [`AsyncActor`](@ref), [`AbstractActor`](@ref)
"""
async(actor::A) where A = as_async(as_actor(A), actor)

as_async(::UndefinedActorTrait, actor)         = throw(UndefinedActorTraitUsageError(actor))
as_async(::ActorTrait{D},       actor) where D = AsyncActor{D}(actor)

close(actor::AsyncActor) = close(actor.channel)
