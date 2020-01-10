export tuple_with_left, tuple_with_right
export TupleWithLeftOperator, TupleWithRightOperator, on_call!, operator_right
export TupleWithLeftProxy, TupleWithRightProxy, actor_proxy!
export TupleWithLeftActor, TupleWithRightActor, on_next!, on_error!, on_complete!

tuple_with_left(value::T) where T = TupleWithLeftOperator{T}(value)

struct TupleWithLeftOperator{T} <: InferableOperator
    value :: T
end

function on_call!(::Type{L}, ::Type{Tuple{T, L}}, operator::TupleWithLeftOperator{T}, source) where T where L
    return ProxyObservable{Tuple{T, L}}(source, TupleWithLeftProxy{T, L}(operator.value))
end

operator_right(operator::TupleWithLeftOperator{T}, ::Type{L}) where T where L = Tuple{T, L}

struct TupleWithLeftProxy{T, L} <: ActorProxy
    value :: T
end

actor_proxy!(proxy::TupleWithLeftProxy{T, L}, actor::A) where { A <: AbstractActor{Tuple{T, L}} } where T where L = TupleWithLeftActor{T, L, A}(proxy.value, actor)

struct TupleWithLeftActor{T, L, A <: AbstractActor{Tuple{T, L}}} <: Actor{L}
    value :: T
    actor :: A
end

on_next!(actor::TupleWithLeftActor{T, L, A}, data::L) where { A <: AbstractActor{Tuple{T, L}} } where T where L = next!(actor.actor, (actor.value, data))
on_error!(actor::TupleWithLeftActor{T, L, A}, err)    where { A <: AbstractActor{Tuple{T, L}} } where T where L = error!(actor.actor, err)
on_complete!(actor::TupleWithLeftActor{T, L, A})      where { A <: AbstractActor{Tuple{T, L}} } where T where L = complete!(actor.actor)

tuple_with_right(value::T) where T = TupleWithRightOperator{T}(value)

struct TupleWithRightOperator{T} <: InferableOperator
    value :: T
end

function on_call!(::Type{L}, ::Type{Tuple{L, T}}, operator::TupleWithRightOperator{T}, source) where T where L
    return ProxyObservable{Tuple{L, T}}(source, TupleWithRightProxy{L, T}(operator.value))
end

operator_right(operator::TupleWithRightOperator{T}, ::Type{L}) where T where L = Tuple{L, T}

struct TupleWithRightProxy{T, L} <: ActorProxy
    value :: T
end

actor_proxy!(proxy::TupleWithRightProxy{T, L}, actor::A) where { A <: AbstractActor{Tuple{L, T}} } where T where L = TupleWithRightActor{T, L, A}(proxy.value, actor)

struct TupleWithRightActor{T, L, A <: AbstractActor{Tuple{L, T}}} <: Actor{L}
    value :: T
    actor :: A
end

on_next!(actor::TupleWithRightActor{T, L, A}, data::L) where { A <: AbstractActor{Tuple{L, T}} } where T where L = next!(actor.actor, (data, actor.value))
on_error!(actor::TupleWithRightActor{T, L, A}, err)    where { A <: AbstractActor{Tuple{L, T}} } where T where L = error!(actor.actor, err)
on_complete!(actor::TupleWithRightActor{T, L, A})      where { A <: AbstractActor{Tuple{L, T}} } where T where L = complete!(actor.actor)
