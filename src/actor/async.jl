export AsyncActor, async, on_next!, on_error!, on_complete!

struct AsyncActor{ D, A <: AbstractActor{D} } <: Actor{D}
    channel :: Channel{D}
    actor   :: A

    AsyncActor{D, A}(actor) where { A <: AbstractActor{D} } where D = begin
        channel = Channel{D}(Inf)

        async_actor = new(channel, actor)

        task = @async begin
            while true
                message = take!(async_actor.channel)
                next!(async_actor.actor, message)
            end
        end

        bind(async_actor.channel, task)

        async_actor
    end
end

function on_next!(actor::AsyncActor{D, A}, data::D) where { A <: AbstractActor{D} } where D
    put!(actor.channel, data)
end

on_error!(actor::AsyncActor{D, A}, err) where { A <: AbstractActor{D} } where D = error!(actor.actor, err)
on_complete!(actor::AsyncActor{D, A}) where { A <: AbstractActor{D} } where D   = complete!(actor.actor)

async(actor::A) where { A <: AbstractActor{D} } where D = AsyncActor{D, A}(actor)
