export tap_on_complete

import Base: show

"""
    tap_on_complete(tapFn::F) where { F <: Function }

Creates a tap operator, which performs a side effect
for only complete emission on the source Observable, but return an Observable that is identical to the source.

# Arguments
- `tapFn::Function`: side-effect tap function with `() -> Nothing` signature

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream

# Examples
```jldoctest
using Rocket

source = from([ 1, 2, 3 ])
subscribe!(source |> tap_on_complete(() -> println("Complete event received")), logger())
;

# output

[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Data: 3
[LogActor] Completed
Complete event received

```

See also: [`tap_on_subscribe`](@ref), [`tap`](@ref), [`logger`](@ref)
"""
tap_on_complete(tapFn::F) where { F <: Function } = TapOnCompleteOperator{F}(tapFn)

struct TapOnCompleteOperator{F} <: InferableOperator
    tapFn :: F
end

operator_right(operator::TapOnCompleteOperator, ::Type{L}) where L = L

function on_call!(::Type{L}, ::Type{L}, operator::TapOnCompleteOperator{F}, source) where { L, F }
    return proxy(L, source, TapOnCompleteProxy{L, F}(operator.tapFn))
end

struct TapOnCompleteProxy{L, F} <: ActorProxy
    tapFn :: F
end

actor_proxy!(proxy::TapOnCompleteProxy{L, F}, actor::A) where { L, A, F } = TapOnCompleteActor{L, A, F}(proxy.tapFn, actor)

struct TapOnCompleteActor{L, A, F} <: Actor{L}
    tapFn :: F
    actor :: A
end

on_next!(actor::TapOnCompleteActor{L}, data::L) where L = next!(actor.actor, data)
on_error!(actor::TapOnCompleteActor, err)               = error!(actor.actor, err)
on_complete!(actor::TapOnCompleteActor)                 = begin complete!(actor.actor); actor.tapFn(); end

Base.show(io::IO, ::TapOnCompleteOperator)         = print(io, "TapOnCompleteOperator()")
Base.show(io::IO, ::TapOnCompleteProxy{L}) where L = print(io, "TapOnCompleteProxy($L)")
Base.show(io::IO, ::TapOnCompleteActor{L}) where L = print(io, "TapOnCompleteActor($L)")
