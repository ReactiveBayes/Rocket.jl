export tap

import Base: show

"""
    tap(tapFn::F) where F

Creates a tap operator, which performs a side effect
for every emission on the source Observable, but return an Observable that is identical to the source.

# Arguments
- `tapFn`: side-effect tap callback with `(data) -> Nothing` signature

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream

# Examples
```jldoctest
using Rocket

source = from([ 1, 2, 3 ])
subscribe!(source |> tap((d) -> println("In tap: \$d")), logger())
;

# output

In tap: 1
[LogActor] Data: 1
In tap: 2
[LogActor] Data: 2
In tap: 3
[LogActor] Data: 3
[LogActor] Completed

```

See also: [`tap_on_subscribe`](@ref), [`tap_on_complete`](@ref), [`logger`](@ref)
"""
tap(tapFn::F) where F = TapOperator{F}(tapFn)

struct TapOperator{F} <: Operator
    tapFn :: F
end

operator_eltype(::TapOperator, ::Type{L}) where L = L

struct TapSubscribable{L, F, S} <: Subscribable{L}
    tapFn  :: F
    source :: S
end

struct TapActor{A, F}
    tapFn :: F
    actor :: A
end

function on_call!(::Type{L}, ::Type{L}, operator::TapOperator{F}, source::S) where { L, F, S }
    return TapSubscribable{L, F, S}(operator.tapFn, source)
end

function on_subscribe!(source::TapSubscribable{L, F}, actor::A) where { L, F, A }
    return subscribe!(source.source, TapActor{A, F}(source.tapFn, actor))
end

on_next!(actor::TapActor, data) = begin actor.tapFn(data); next!(actor.actor, data) end
on_error!(actor::TapActor, err) = error!(actor.actor, err)
on_complete!(actor::TapActor)   = complete!(actor.actor)

Base.show(io::IO, ::TapOperator)                = print(io, "TapOperator()")
Base.show(io::IO, ::TapSubscribable{L}) where L = print(io, "TapSubscribable($L)")
Base.show(io::IO, ::TapActor)                   = print(io, "TapActor()")
