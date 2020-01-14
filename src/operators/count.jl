export count
export CountOperator, on_call!
export CountProxy, actor_proxy!
export CountActor, on_next!, on_error!, on_complete!, is_exhausted

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

function on_call!(::Type{L}, ::Type{Int}, operator::CountOperator, source) where L
    return ProxyObservable{Int}(source, CountProxy{L}())
end

struct CountProxy{L} <: ActorProxy end

actor_proxy!(proxy::CountProxy{L}, actor) where L = CountActor{L}(0, actor)

mutable struct CountActor{L} <: Actor{L}
    current :: Int
    actor
end

is_exhausted(actor::CountActor) = is_exhausted(actor.actor)

function on_next!(c::CountActor{L}, data::L) where L
    c.current += 1
end

function on_error!(c::CountActor, err)
    error!(c.actor, err)
end

function on_complete!(c::CountActor)
    next!(c.actor, c.current)
    complete!(c.actor)
end
