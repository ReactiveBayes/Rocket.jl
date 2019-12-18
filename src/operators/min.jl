export min
export MinOperator, on_call!
export MinProxy, actor_proxy!
export MinActor, on_next!, on_error!, on_complete!

import Base: min

"""
    min(; from = nothing)

Creates a min operator, which emits a single item: the item with the smallest value.

# Arguments
- `from`: optional initial minimal value, if `nothing` first item from the source will be used as initial instead

# Producing

Stream of type <: Subscribable{Union{L, Nothing}} where L refers to type of source stream

# Examples
```jldoctest
using Rx

source = from([ i for i in 1:42 ])
subscribe!(source |> min(), LoggerActor{Int}())
;

# output

[LogActor] Data: 1
[LogActor] Completed

```

See also: [`Operator`](@ref), ['ProxyObservable'](@ref)
"""
min(; from = nothing) = MinOperator(from)

struct MinOperator <: InferrableOperator
    from
end

function on_call!(::Type{L}, ::Type{Union{L, Nothing}}, operator::MinOperator, source::S) where { S <: Subscribable{L} } where L
    return ProxyObservable{Union{L, Nothing}}(source, MinProxy{L}(operator.from != nothing ? convert(L, operator.from) : nothing))
end

operator_right(operator::MinOperator, ::Type{L}) where L = Union{L, Nothing}

struct MinProxy{L} <: ActorProxy
    from :: Union{L, Nothing}
end

actor_proxy!(proxy::MinProxy{L}, actor::A) where { A <: AbstractActor{Union{L, Nothing}} } where L = MinActor{L, A}(proxy.from, actor)

mutable struct MinActor{L, A <: AbstractActor{Union{L, Nothing}} } <: Actor{L}
    current :: Union{L, Nothing}
    actor   :: A
end

function on_next!(actor::MinActor{L, A}, data::L) where { A <: AbstractActor{Union{L, Nothing}} } where L
    if actor.current == nothing
        actor.current = data
    else
        actor.current = data < actor.current ? data : actor.current
    end
end

function on_error!(actor::MinActor, err)
    error!(actor.actor, error)
end

function on_complete!(actor::MinActor)
    next!(actor.actor, actor.current)
    complete!(actor.actor)
end
