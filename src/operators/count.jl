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
    return proxy(Int, source, CountProxy())
end

struct CountProxy <: ActorProxy end

actor_proxy!(::Type, proxy::CountProxy, actor::A) where A = CountActor{A}(actor)

mutable struct CountActor{A} <: Actor{Any}
    actor   :: A
    current :: Int

    CountActor{A}(actor::A) where A = new(actor, 0)
end

on_next!(actor::CountActor, data) = begin actor.current += 1 end
on_error!(actor::CountActor, err) = begin error!(actor.actor, err) end
on_complete!(actor::CountActor)   = begin next!(actor.actor, actor.current); complete!(actor.actor) end

Base.show(io::IO, ::CountOperator) = print(io, "CountOperator()")
Base.show(io::IO, ::CountProxy)    = print(io, "CountProxy()")
Base.show(io::IO, ::CountActor)    = print(io, "CountActor()")
