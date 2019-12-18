export AsyncActor, async
export on_next!, on_error!, on_complete!
export close

import Base: close

"""
    AsyncActor{D, A}(actor::A) where { A <: AbstractActor{D} } where D

AsyncActor wraps an actor and send a data from a stream to this actor asynchronously in a different `Task`.
You have to `close` this actor when you do not need it.

# Constructor arguments
- `actor`: any actor to be wrapped

See also: [`Actor`](@ref), [`async`](@ref)
"""
struct AsyncActor{ D, A <: AbstractActor{D} } <: Actor{D}
    channel :: Channel{D}
    actor   :: A

    AsyncActor{D, A}(actor::A) where { A <: AbstractActor{D} } where D = begin
        channel = Channel{D}(Inf, spawn = true) do ch
            while true
                message = take!(ch)
                next!(actor, message)
            end
        end
        new(channel, actor)
    end
end

function on_next!(actor::AsyncActor{D, A}, data::D) where { A <: AbstractActor{D} } where D
    put!(actor.channel, data)
end

on_error!(actor::AsyncActor{D, A}, err) where { A <: AbstractActor{D} } where D = error!(actor.actor, err)
on_complete!(actor::AsyncActor{D, A}) where { A <: AbstractActor{D} } where D   = complete!(actor.actor)

"""
    async(actor::A) where { A <: AbstractActor{D} } where D

Helper function to create an AsyncActor

See also: [`AsyncActor`](@ref), [`AbstractActor`](@ref)
"""
async(actor::A) where { A <: AbstractActor{D} } where D = AsyncActor{D, A}(actor)

close(actor::AsyncActor) = close(actor.channel)
