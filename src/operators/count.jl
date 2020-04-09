export count

import Base: count
import Base: show

"""
    count()

Creates a count operator, which counts the number of
emissions on the source and emits that number when the source completes.

# Producing

Stream of type `<: Subscribable{Int}`

# Examples
```jldoctest
using Rocket

source = from([ i for i in 1:42 ])
subscribe!(source |> count(), logger())
;

# output

[LogActor] Data: 42
[LogActor] Completed

```

See also: [`AbstractOperator`](@ref), [`RightTypedOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
count() = CountOperator()

struct CountOperator <: RightTypedOperator{Int} end

function on_call!(::Type{L}, ::Type{Int}, operator::CountOperator, source) where L
    return proxy(Int, source, CountProxy{L}())
end

struct CountProxy{L} <: ActorProxy end

actor_proxy!(proxy::CountProxy{L}, actor::A) where { L, A } = CountActor{L, A}(0, actor)

mutable struct CountActor{L, A} <: Actor{L}
    current :: Int
    actor   :: A
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

Base.show(io::IO, ::CountOperator)         = print(io, "CountOperator()")
Base.show(io::IO, ::CountProxy{L}) where L = print(io, "CountProxy($L)")
Base.show(io::IO, ::CountActor{L}) where L = print(io, "CountActor($L)")
