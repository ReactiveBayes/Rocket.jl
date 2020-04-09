export tap_on_subscribe

import Base: show

"""
    tap_on_subscribe(tapFn::F) where { F <: Function }

Creates a tap operator, which performs a side effect on the subscription on the source Observable, but return an Observable that is identical to the source.

# Arguments
- `tapFn::Function`: side-effect tap function with `() -> Nothing` signature

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream

# Examples
```jldoctest
using Rocket

source = from([ 1, 2, 3 ])
subscribe!(source |> tap_on_subscribe(() -> println("Someone subscribed")), logger())
;

# output

Someone subscribed
[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Data: 3
[LogActor] Completed

```

See also: [`tap`](@ref), [`tap_on_complete`](@ref), [`logger`](@ref)
"""
tap_on_subscribe(tapFn::F) where { F <: Function } = TapOnSubscribeOperator{F}(tapFn)

struct TapOnSubscribeOperator{F} <: InferableOperator
    tapFn :: F
end

operator_right(operator::TapOnSubscribeOperator, ::Type{L}) where L = L

function on_call!(::Type{L}, ::Type{L}, operator::TapOnSubscribeOperator{F}, source) where { L, F }
    return proxy(L, source, TapOnSubscribeProxy{L, F}(operator.tapFn))
end

struct TapOnSubscribeProxy{L, F} <: SourceProxy
    tapFn :: F
end

source_proxy!(proxy::TapOnSubscribeProxy{L, F}, source::S) where { L, S, F } = TapOnSubscribeSource{L, S, F}(proxy.tapFn, source)

struct TapOnSubscribeSource{L, S, F} <: Subscribable{L}
    tapFn  :: F
    source :: S
end

function on_subscribe!(source::TapOnSubscribeSource, actor)
    source.tapFn()
    return subscribe!(source.source, actor)
end

Base.show(io::IO, ::TapOnSubscribeOperator)          = print(io, "TapOnSubscribeOperator()")
Base.show(io::IO, ::TapOnSubscribeProxy{L})  where L = print(io, "TapOnSubscribeProxy($L)")
Base.show(io::IO, ::TapOnSubscribeSource{L}) where L = print(io, "TapOnSubscribeSource($L)")
