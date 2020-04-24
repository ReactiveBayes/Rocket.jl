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

actor_proxy!(proxy::CountProxy{L}, actor::A) where { L, A } = CountActor{L, A}(actor)

mutable struct CountActorProps
    current :: Int

    CountActorProps() = new(0)
end

struct CountActor{L, A} <: Actor{L}
    actor :: A
    props :: CountActorProps

    CountActor{L, A}(actor::A) where { L, A } = new(actor, CountActorProps())
end

is_exhausted(actor::CountActor) = is_exhausted(actor.actor)

on_next!(actor::CountActor, data) = begin actor.props.current += 1 end
on_error!(actor::CountActor, err) = begin error!(actor.actor, err) end
on_complete!(actor::CountActor)   = begin next!(actor.actor, actor.props.current); complete!(actor.actor) end

Base.show(io::IO, ::CountOperator)         = print(io, "CountOperator()")
Base.show(io::IO, ::CountProxy{L}) where L = print(io, "CountProxy($L)")
Base.show(io::IO, ::CountActor{L}) where L = print(io, "CountActor($L)")
