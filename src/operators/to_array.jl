export to_array
export ToArrayOperator, on_call!, operator_right
export ToArrayProxy, actor_proxy!
export ToArrayActor, on_next!, on_error!, on_complete!

to_array() = ToArrayOperator()

struct ToArrayOperator <: InferableOperator end

function on_call!(::Type{L}, ::Type{Vector{L}}, operator::ToArrayOperator, source::S) where { S <: Subscribable{L} } where L
    return ProxyObservable{Vector{L}}(source, ToArrayProxy{L}())
end

operator_right(operator::ToArrayOperator, ::Type{L}) where L = Vector{L}

struct ToArrayProxy{L} <: ActorProxy end

actor_proxy!(proxy::ToArrayProxy{L}, actor::A) where { A <: AbstractActor{Vector{L}} } where L = ToArrayActor{L, A}(actor)

struct ToArrayActor{L, A <: AbstractActor{Vector{L}}} <: Actor{L}
    values :: Vector{L}
    actor  :: A

    ToArrayActor{L, A}(actor::A) where { A <: AbstractActor{Vector{L}} } where L = new(Vector{L}(), actor)
end

on_next!(actor::ToArrayActor{L, A}, data::L) where { A <: AbstractActor{Vector{L}} } where L = push!(actor.values, data)
on_error!(actor::ToArrayActor, err)          = error!(actor.actor, err)

function on_complete!(actor::ToArrayActor)
    next!(actor.actor, actor.values)
    complete!(actor.actor)
end
