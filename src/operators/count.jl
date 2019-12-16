export count
export CountOperator, on_call!
export CountProxy, actor_proxy!
export CountActor, on_next!, on_error!, on_complete!

import Base: count

"""
    count(::Type{T}) where T

Creates a count operator, which counts the number of
emissions on the source and emits that number when the source completes.

# Arguments
- `::Type{T}`: the type of data of source

# Examples
```jldoctest
using Rx

source = from([ i for i in 1:42 ])
subscribe!(source |> count(Int), LoggerActor{Int}())
;

# output

[LogActor] Data: 42
[LogActor] Completed

```

See also: [`Operator`](@ref), ['ProxyObservable'](@ref)
"""
count(::Type{T}) where T = CountOperator{T}()

struct CountOperator{T} <: Operator{T, Int} end

function on_call!(operator::CountOperator{T}, source::S) where { S <: Subscribable{T} } where T
    return ProxyObservable{Int}(source, CountProxy{T}())
end

struct CountProxy{T} <: ActorProxy end

actor_proxy!(proxy::CountProxy{T}, actor::A) where { A <: AbstractActor{Int} } where T = CountActor{T}(actor)

mutable struct CountActor{T} <: Actor{T}
    current :: Int
    actor

    CountActor{T}(actor) where T = new(0, actor)
end

function on_next!(c::CountActor{T}, data::T) where T
    c.current += 1
end

on_error!(c::CountActor{T}, error) where T = error!(c.actor, error)

function on_complete!(c::CountActor{T})     where T
    next!(c.actor, c.current)
    complete!(c.actor)
end
