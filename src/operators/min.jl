export min
export MinOperator, on_call!
export MinProxy, actor_proxy!
export MinActor, on_next!, on_error!, on_complete!

import Base: min

"""
    min(::Type{T}, from = nothing) where T

Creates a min operator, which emits a single item: the item with the smallest value.

# Arguments
- `::Type{T}`: the type of data of source
- `from`: optional initial minimal value, if `nothing` first item from the source will be used as initial instead

# Examples
```jldoctest
using Rx

source = from([ i for i in 1:42 ])
subscribe!(source |> min(Int), LoggerActor{Int}())
;

# output

[LogActor] Data: 1
[LogActor] Completed

```

See also: [`Operator`](@ref), ['ProxyObservable'](@ref)
"""
min(::Type{T}, from = nothing) where T = MinOperator{T}(from)

struct MinOperator{T} <: Operator{T, T}
    from :: Union{Nothing, T}
end

function on_call!(operator::MinOperator{T}, source::S) where { S <: Subscribable{T} } where T
    return ProxyObservable{T}(source, MinProxy{T}(operator.from))
end

struct MinProxy{T} <: ActorProxy
    from :: Union{Nothing, T}
end

actor_proxy!(proxy::MinProxy{T}, actor::A) where { A <: AbstractActor{T} } where T = MinActor{T}(proxy.from, actor)

mutable struct MinActor{T} <: Actor{T}
    current :: Union{Nothing, T}
    actor
end

function on_next!(actor::MinActor{T}, data::T) where T
    if actor.current == nothing
        actor.current = data
    else
        actor.current = data < actor.current ? data : actor.current
    end
end

on_error!(actor::MinActor{T}, error) where T = error!(actor.actor, error)

function on_complete!(actor::MinActor{T}) where T
    next!(actor.actor, actor.current)
    complete!(actor.actor)
end
