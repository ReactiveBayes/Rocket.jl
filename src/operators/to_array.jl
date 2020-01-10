export to_array
export ToArrayOperator, on_call!, operator_right
export ToArrayProxy, actor_proxy!
export ToArrayActor, on_next!, on_error!, on_complete!

"""
    to_array()

Creates a `to_array` operator, which reduces all values into a single array and returns this result when the source completes.

# Producing

Stream of type `<: Subscribable{Vector{L}}` where `L` refers to type of source stream

# Examples
```jldoctest
using Rx

source = from([ 1, 2, 3 ])
subscribe!(source |> to_array(), LoggerActor{Vector{Int}}())
;

# output

[LogActor] Data: [1, 2, 3]
[LogActor] Completed

```

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref)
"""
to_array() = ToArrayOperator()

struct ToArrayOperator <: InferableOperator end

function on_call!(::Type{L}, ::Type{Vector{L}}, operator::ToArrayOperator, source) where L
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
on_error!(actor::ToArrayActor{L, A}, err)    where { A <: AbstractActor{Vector{L}} } where L = error!(actor.actor, err)

function on_complete!(actor::ToArrayActor{L, A}) where { A <: AbstractActor{Vector{L}} } where L
    next!(actor.actor, actor.values)
    complete!(actor.actor)
end
