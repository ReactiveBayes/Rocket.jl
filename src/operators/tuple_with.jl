export tuple_with_left, tuple_with_right

import Base: show

tuple_with_left(value::T) where T = TupleWithLeftOperator{T}(value)

struct TupleWithLeftOperator{T} <: InferableOperator
    value :: T
end

function on_call!(::Type{L}, ::Type{Tuple{T, L}}, operator::TupleWithLeftOperator{T}, source) where T where L
    return proxy(Tuple{T, L}, source, TupleWithLeftProxy{T, L}(operator.value))
end

operator_right(operator::TupleWithLeftOperator{T}, ::Type{L}) where T where L = Tuple{T, L}

struct TupleWithLeftProxy{T, L} <: ActorProxy
    value :: T
end

actor_proxy!(proxy::TupleWithLeftProxy{T, L}, actor::A) where T where L where A = TupleWithLeftActor{T, L, A}(proxy.value, actor)

struct TupleWithLeftActor{T, L, A} <: Actor{L}
    value :: T
    actor :: A
end

is_exhausted(actor::TupleWithLeftActor) = is_exhausted(actor.actor)

on_next!(actor::TupleWithLeftActor{T, L}, data::L) where T where L = next!(actor.actor, (actor.value, data))
on_error!(actor::TupleWithLeftActor, err)                          = error!(actor.actor, err)
on_complete!(actor::TupleWithLeftActor)                            = complete!(actor.actor)

Base.show(io::IO, operator::TupleWithLeftOperator)                 = print(io, "TupleWithLeftOperator()")
Base.show(io::IO, proxy::TupleWithLeftProxy{T, L}) where T where L = print(io, "TupleWithLeftProxy($L)")
Base.show(io::IO, actor::TupleWithLeftActor{T, L}) where T where L = print(io, "TupleWithLeftActor($L)")

tuple_with_right(value::T) where T = TupleWithRightOperator{T}(value)

struct TupleWithRightOperator{T} <: InferableOperator
    value :: T
end

function on_call!(::Type{L}, ::Type{Tuple{L, T}}, operator::TupleWithRightOperator{T}, source) where T where L
    return proxy(Tuple{L, T}, source, TupleWithRightProxy{L, T}(operator.value))
end

operator_right(operator::TupleWithRightOperator{T}, ::Type{L}) where T where L = Tuple{L, T}

struct TupleWithRightProxy{T, L} <: ActorProxy
    value :: T
end

actor_proxy!(proxy::TupleWithRightProxy{T, L}, actor::A) where T where L where A = TupleWithRightActor{T, L, A}(proxy.value, actor)

struct TupleWithRightActor{T, L, A} <: Actor{L}
    value :: T
    actor :: A
end

is_exhausted(actor::TupleWithRightActor) = is_exhausted(actor.actor)

on_next!(actor::TupleWithRightActor{T, L}, data::L) where T where L = next!(actor.actor, (data, actor.value))
on_error!(actor::TupleWithRightActor, err)                          = error!(actor.actor, err)
on_complete!(actor::TupleWithRightActor)                            = complete!(actor.actor)

Base.show(io::IO, operator::TupleWithRightOperator)                 = print(io, "TupleWithRightOperator()")
Base.show(io::IO, proxy::TupleWithRightProxy{T, L}) where T where L = print(io, "TupleWithRightProxy($L)")
Base.show(io::IO, actor::TupleWithRightActor{T, L}) where T where L = print(io, "TupleWithRightActor($L)")
