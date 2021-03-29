export pairwise

import Base: show

"""
    pairwise()

Creates a pairwise operator, which groups pairs of consecutive emissions together and emits them as a tuple of two values.

```
using Rocket

source = from(1:5) |> pairwise()

subscribe!(source, logger())
;

# output

[LogActor] Data  (1, 2)
[LogActor] Data: (2, 3)
[LogActor] Data: (3, 4)
[LogActor] Data: (4, 5)
[LogActor] Completed
```

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`logger`](@ref)
"""
pairwise() = PairwiseOperator()

struct PairwiseOperator <: InferableOperator end

operator_right(::PairwiseOperator, ::Type{L}) where L = Tuple{L, L}

function on_call!(::Type{L}, ::Type{ Tuple{L, L} }, ::PairwiseOperator, source) where L
    return proxy(Tuple{L, L}, source, PairwiseProxy{L}())
end

struct PairwiseProxy{L} <: ActorProxy end

actor_proxy!(::Type{ Tuple{L, L} }, ::PairwiseProxy{L}, actor::A) where { L, A } = PairwiseActor{L, A}(actor, nothing)

mutable struct PairwiseActor{L, A} <: Actor{L}
    actor    :: A
    previous :: Union{Nothing, L}
end

function on_next!(actor::PairwiseActor{L}, data::L) where L 
    if actor.previous !== nothing
        next!(actor.actor, (actor.previous, data))
    end
    actor.previous = data
end

on_error!(actor::PairwiseActor, err) = error!(actor.actor, err)
on_complete!(actor::PairwiseActor)   = complete!(actor.actor)

Base.show(io::IO, ::PairwiseOperator)          = print(io, "PairwiseOperator()")
Base.show(io::IO, ::PairwiseProxy)             = print(io, "PairwiseProxy()")
Base.show(io::IO, ::PairwiseActor{L})  where L = print(io, "PairwiseActor($L)")
