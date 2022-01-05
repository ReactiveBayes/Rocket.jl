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
    tap_on_subscribe(tap, strategy::S = TapBeforeSubscription())

Creates a tap operator, which performs a side effect on the subscription on the source Observable, but return an Observable that is identical to the source.

# Arguments
- `tap`: side-effect tap callback with `() -> Nothing` signature
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
tap_on_subscribe(tap::F, strategy::T = TapBeforeSubscription()) where { F, T } = TapOnSubscribeOperator{F, T}(tap, strategy)

struct TapOnSubscribeOperator{F, T} <: Operator
    tap      :: F
    strategy :: T
end

operator_eltype(::TapOnSubscribeOperator, ::Type{L}) where L = L

struct TapOnSubscribeSubscribable{L, F, T, S} <: Subscribable{L}
    tap      :: F
    strategy :: T
    source   :: S
end

function on_call!(::Type{L}, ::Type{L}, operator::TapOnSubscribeOperator{F, T}, source::S) where { L, F, T, S }
    return TapOnSubscribeSubscribable{L, F, T, S}(operator.tap, operator.strategy, source)
end

function on_subscribe!(source::TapOnSubscribeSubscribable, actor) 
    return __on_subscribe_with_tap(source.strategy, source, actor)
end

function __on_subscribe_with_tap(::TapBeforeSubscription, source::TapOnSubscribeSubscribable, actor)
    source.tap()
    return subscribe!(source.source, actor)
end

function __on_subscribe_with_tap(::TapAfterSubscription, source::TapOnSubscribeSubscribable, actor)
    subscription = subscribe!(source.source, actor)
    source.tap()
    return subscription
end

Base.show(io::IO, ::TapOnSubscribeOperator)                = print(io, "TapOnSubscribeOperator()")
Base.show(io::IO, ::TapOnSubscribeSubscribable{L}) where L = print(io, "TapOnSubscribeSubscribable($L)")
