export tap_on_subscribe, TapBeforeSubscription, TapAfterSubscription

import Base: show

"""
    TapBeforeSubscription

One of the strategies for `tap_on_subscribe` operator. With `TapBeforeSubscription` tap callback will be called before actual subscription.

See also: [`tap_on_subscribe`](@ref), [`TapAfterSubscription`](@ref)
"""
struct TapBeforeSubscription end

"""
    TapAfterSubscription

One of the strategies for `tap_on_subscribe` operator. With `TapBeforeSubscription` tap callback will be called after actual subscription.

See also: [`tap_on_subscribe`](@ref), [`TapBeforeSubscription`](@ref)
"""
struct TapAfterSubscription end

"""
    tap_on_subscribe(tapFn::F, strategy::S = TapBeforeSubscription()) where { F <: Function }

Creates a tap operator, which performs a side effect on the subscription on the source Observable, but return an Observable that is identical to the source.

# Arguments
- `tapFn::Function`: side-effect tap function with `() -> Nothing` signature
- `strategy`: (optional), specifies the order of a side-effect and an actual subscription, uses `TapBeforeSubscription` by default

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

```jldoctest
using Rocket

source = from([ 1, 2, 3 ])
subscribe!(source |> tap_on_subscribe(() -> println("Someone subscribed"), TapAfterSubscription()), logger())
;

# output

[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Data: 3
[LogActor] Completed
Someone subscribed
```

See also: [`TapBeforeSubscription`](@ref), [`TapAfterSubscription`](@ref), [`tap`](@ref), [`tap_on_unsubscribe`](@ref), [`tap_on_complete`](@ref), [`logger`](@ref)
"""
tap_on_subscribe(tapFn::F, strategy::S = TapBeforeSubscription()) where {F<:Function,S} =
    TapOnSubscribeOperator{F,S}(tapFn, strategy)

struct TapOnSubscribeOperator{F,S} <: InferableOperator
    tapFn::F
    strategy::S
end

operator_right(::TapOnSubscribeOperator, ::Type{L}) where {L} = L

function on_call!(
    ::Type{L},
    ::Type{L},
    operator::TapOnSubscribeOperator{F,S},
    source,
) where {L,F,S}
    return proxy(L, source, TapOnSubscribeProxy{F,S}(operator.tapFn, operator.strategy))
end

struct TapOnSubscribeProxy{F,S} <: SourceProxy
    tapFn::F
    strategy::S
end

source_proxy!(::Type{L}, proxy::TapOnSubscribeProxy{F,T}, source::S) where {L,S,F,T} =
    TapOnSubscribeSource{L,S,F,T}(proxy.tapFn, proxy.strategy, source)

@subscribable struct TapOnSubscribeSource{L,S,F,T} <: Subscribable{L}
    tapFn::F
    strategy::T
    source::S
end

on_subscribe!(source::TapOnSubscribeSource, actor) =
    __on_subscribe_with_tap(source.strategy, source, actor)

function __on_subscribe_with_tap(
    ::TapBeforeSubscription,
    source::TapOnSubscribeSource,
    actor,
)
    source.tapFn()
    return subscribe!(source.source, actor)
end

function __on_subscribe_with_tap(
    ::TapAfterSubscription,
    source::TapOnSubscribeSource,
    actor,
)
    subscription = subscribe!(source.source, actor)
    source.tapFn()
    return subscription
end

Base.show(io::IO, ::TapOnSubscribeOperator) = print(io, "TapOnSubscribeOperator()")
Base.show(io::IO, ::TapOnSubscribeProxy) = print(io, "TapOnSubscribeProxy()")
Base.show(io::IO, ::TapOnSubscribeSource{L}) where {L} =
    print(io, "TapOnSubscribeSource($L)")
