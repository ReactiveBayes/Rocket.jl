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

actor_proxy!(proxy::TupleWithLeftProxy{T, L}, actor) where T where L = TupleWithLeftActor{T, L}(proxy.value, actor)

struct TupleWithLeftActor{T, L} <: Actor{L}
    value :: T
    actor
end

on_next!(actor::TupleWithLeftActor{T, L}, data::L) where T where L = next!(actor.actor, (actor.value, data))
on_error!(actor::TupleWithLeftActor, err)                          = error!(actor.actor, err)
on_complete!(actor::TupleWithLeftActor)                            = complete!(actor.actor)

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

actor_proxy!(proxy::TupleWithRightProxy{T, L}, actor) where T where L = TupleWithRightActor{T, L}(proxy.value, actor)

struct TupleWithRightActor{T, L} <: Actor{L}
    value :: T
    actor
end

on_next!(actor::TupleWithRightActor{T, L}, data::L) where T where L = next!(actor.actor, (data, actor.value))
on_error!(actor::TupleWithRightActor, err)                          = error!(actor.actor, err)
on_complete!(actor::TupleWithRightActor)                            = complete!(actor.actor)
