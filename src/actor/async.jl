export AsyncActor, async
export close

import Base: close

"""
    AsyncActor{D, A}(actor::A) where D where A

AsyncActor wraps an actor and send a data from a stream to this actor asynchronously in a different `Task`.
You have to `close` this actor when you do not need it.

# Constructor arguments
- `actor`: any actor to be wrapped

See also: [`Actor`](@ref), [`async`](@ref)
"""
struct AsyncActor{D, A} <: Actor{D}
    channel :: Channel{D}
    actor   :: A

    AsyncActor{D, A}(actor::A) where D where A = begin

        channel = Channel{D}(Inf)
        task    = @async begin
            while true
                message = take!(ch)::D
                next!(actor, message)
            end
        end

        bind(channel, task)

        return new(channel, actor)
    end
end

is_exhausted(actor::AsyncActor) = is_exhausted(actor.actor)

function on_next!(actor::AsyncActor{D}, data::D) where D
    put!(actor.channel, data)
end

on_error!(actor::AsyncActor, err) = error!(actor.actor, err)
on_complete!(actor::AsyncActor)   = complete!(actor.actor)

"""
    async(actor::A) where A

Creation operator for the `AsyncActor` actor.

# Examples

```jldoctest
using Rocket

actor = async(keep(Int))
actor isa AsyncActor{Int, KeepActor{Int}}

# output
true
```

See also: [`AsyncActor`](@ref), [`AbstractActor`](@ref)
"""
async(actor::A) where A = as_async(as_actor(A), actor)

as_async(::InvalidActorTrait, actor)                    = throw(InvalidActorTraitUsageError(actor))
as_async(::ActorTrait{D},     actor::A) where D where A = AsyncActor{D, A}(actor)

close(actor::AsyncActor) = close(actor.channel)
