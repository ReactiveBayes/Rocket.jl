export tuple_with_left, tuple_with_right

import Base: show

tuple_with_left(value::T) where {T} = TupleWithLeftOperator{T}(value)

struct TupleWithLeftOperator{T} <: InferableOperator
    value::T
end

function on_call!(
    ::Type{L},
    ::Type{Tuple{T,L}},
    operator::TupleWithLeftOperator{T},
    source,
) where {T} where {L}
    return proxy(Tuple{T,L}, source, TupleWithLeftProxy{T}(operator.value))
end

operator_right(operator::TupleWithLeftOperator{T}, ::Type{L}) where {T,L} = Tuple{T,L}

struct TupleWithLeftProxy{T} <: ActorProxy
    value::T
end

actor_proxy!(::Type{Tuple{T,L}}, proxy::TupleWithLeftProxy{T}, actor::A) where {T,L,A} =
    TupleWithLeftActor{T,L,A}(proxy.value, actor)

struct TupleWithLeftActor{T,L,A} <: Actor{L}
    value::T
    actor::A
end

on_next!(actor::TupleWithLeftActor{T,L}, data::L) where {T,L} =
    next!(actor.actor, (actor.value, data))
on_error!(actor::TupleWithLeftActor, err) = error!(actor.actor, err)
on_complete!(actor::TupleWithLeftActor) = complete!(actor.actor)

Base.show(io::IO, ::TupleWithLeftOperator) = print(io, "TupleWithLeftOperator()")
Base.show(io::IO, ::TupleWithLeftProxy{T}) where {T} = print(io, "TupleWithLeftProxy()")
Base.show(io::IO, ::TupleWithLeftActor{T,L}) where {T,L} =
    print(io, "TupleWithLeftActor($L -> Tuple{$T, $L})")

tuple_with_right(value::T) where {T} = TupleWithRightOperator{T}(value)

struct TupleWithRightOperator{T} <: InferableOperator
    value::T
end

function on_call!(
    ::Type{L},
    ::Type{Tuple{L,T}},
    operator::TupleWithRightOperator{T},
    source,
) where {T} where {L}
    return proxy(Tuple{L,T}, source, TupleWithRightProxy{T}(operator.value))
end

operator_right(operator::TupleWithRightOperator{T}, ::Type{L}) where {T,L} = Tuple{L,T}

struct TupleWithRightProxy{T} <: ActorProxy
    value::T
end

actor_proxy!(::Type{Tuple{L,T}}, proxy::TupleWithRightProxy{T}, actor::A) where {T,L,A} =
    TupleWithRightActor{T,L,A}(proxy.value, actor)

struct TupleWithRightActor{T,L,A} <: Actor{L}
    value::T
    actor::A
end

on_next!(actor::TupleWithRightActor{T,L}, data::L) where {T,L} =
    next!(actor.actor, (data, actor.value))
on_error!(actor::TupleWithRightActor, err) = error!(actor.actor, err)
on_complete!(actor::TupleWithRightActor) = complete!(actor.actor)

Base.show(io::IO, ::TupleWithRightOperator) = print(io, "TupleWithRightOperator()")
Base.show(io::IO, ::TupleWithRightProxy{T}) where {T} = print(io, "TupleWithRightProxy()")
Base.show(io::IO, ::TupleWithRightActor{T,L}) where {T,L} =
    print(io, "TupleWithRightActor($L -> Tuple{$L, $T})")
