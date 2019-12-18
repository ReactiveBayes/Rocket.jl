export count
export CountOperator, on_call!
export CountProxy, actor_proxy!
export CountActor, on_next!, on_error!, on_complete!

import Base: count

"""
    count()

Creates a count operator, which counts the number of
emissions on the source and emits that number when the source completes.

# Producing

Stream of type `<: Subscribable{Int}`

# Examples
```jldoctest
using Rx

source = from([ i for i in 1:42 ])
subscribe!(source |> count(), LoggerActor{Int}())
;

# output

[LogActor] Data: 42
[LogActor] Completed

```

See also: [`AbstractOperator`](@ref), [`RightTypedOperator`](@ref), [`ProxyObservable`](@ref)
"""
count() = CountOperator()

struct CountOperator <: RightTypedOperator{Int} end

function on_call!(::Type{L}, ::Type{Int}, operator::CountOperator, source::S) where { S <: Subscribable{L} } where L
    return ProxyObservable{Int}(source, CountProxy{L}())
end

struct CountProxy{L} <: ActorProxy end

actor_proxy!(proxy::CountProxy{L}, actor::A) where { A <: AbstractActor{Int} } where L = CountActor{L, A}(0, actor)

mutable struct CountActor{L, A <: AbstractActor{Int} } <: Actor{L}
    current :: Int
    actor   :: A
end

function on_next!(c::CountActor{L, A}, data::L) where { A <: AbstractActor{Int} } where L
    c.current += 1
end

function on_error!(c::CountActor, err)
    error!(c.actor, err)
end

function on_complete!(c::CountActor)
    next!(c.actor, c.current)
    complete!(c.actor)
end
