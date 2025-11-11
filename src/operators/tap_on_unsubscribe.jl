export tap_on_unsubscribe, TapBeforeUnsubscription, TapAfterUnsubscription

import Base: show

"""
    TapBeforeUnsubscription

One of the strategies for `tap_on_unsubscribe` operator. With `TapBeforeUnubscription` tap callback will be called before actual unsubscription.

See also: [`tap_on_unsubscribe`](@ref), [`TapAfterUnsubscription`](@ref)
"""
struct TapBeforeUnsubscription end

"""
    TapAfterUnsubscription

One of the strategies for `tap_on_unsubscribe` operator. With `TapBeforeUnsubscription` tap callback will be called after actual unsubscription.

See also: [`tap_on_unsubscribe`](@ref), [`TapBeforeUnsubscription`](@ref)
"""
struct TapAfterUnsubscription end

"""
    tap_on_unsubscribe(tapFn::F, strategy::S = TapBeforeUnsubscription()) where { F <: Function }

Creates a tap operator, which performs a side effect on the unsubscription on the source Observable, but return an Observable that is identical to the source. Tap callback triggers only once.

# Arguments
- `tapFn::Function`: side-effect tap function with `() -> Nothing` signature
- `strategy`: (optional), specifies the order of a side-effect and an actual unsubscription, uses `TapBeforeUnsubscription` by default

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream

# Examples
```jldoctest
using Rocket

source = from([ 1, 2, 3 ])
subscription = subscribe!(source |> tap_on_unsubscribe(() -> println("Someone unsubscribed")), logger())
unsubscribe!(subscription)
;

# output

[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Data: 3
[LogActor] Completed
Someone unsubscribed
```

See also: [`TapBeforeUnsubscription`](@ref), [`TapAfterUnsubscription`](@ref), [`tap`](@ref), [`tap_on_subscribe`](@ref), [`tap_on_complete`](@ref), [`logger`](@ref)
"""
tap_on_unsubscribe(
    tapFn::F,
    strategy::S = TapBeforeUnsubscription(),
) where {F<:Function,S} = TapOnUnsubscribeOperator{F,S}(tapFn, strategy)

struct TapOnUnsubscribeOperator{F,S} <: InferableOperator
    tapFn::F
    strategy::S
end

operator_right(::TapOnUnsubscribeOperator, ::Type{L}) where {L} = L

function on_call!(
    ::Type{L},
    ::Type{L},
    operator::TapOnUnsubscribeOperator{F,S},
    source,
) where {L,F,S}
    return proxy(L, source, TapOnUnsubscribeProxy{F,S}(operator.tapFn, operator.strategy))
end

struct TapOnUnsubscribeProxy{F,S} <: SourceProxy
    tapFn::F
    strategy::S
end

source_proxy!(::Type{L}, proxy::TapOnUnsubscribeProxy{F,T}, source::S) where {L,S,F,T} =
    TapOnUnsubscribeSource{L,S,F,T}(proxy.tapFn, proxy.strategy, source)

@subscribable struct TapOnUnsubscribeSource{L,S,F,T} <: Subscribable{L}
    tapFn::F
    strategy::T
    source::S
end

mutable struct TapOnUnsubscribeSubscription{S,F,T} <: Teardown
    is_unsubscribed::Bool
    tapFn::F
    strategy::T
    subscription::S
end

as_teardown(::Type{<: TapOnUnsubscribeSubscription}) = UnsubscribableTeardownLogic()

function on_subscribe!(source::TapOnUnsubscribeSource{L,S,F,T}, actor) where {L,S,F,T}
    return TapOnUnsubscribeSubscription(
        false,
        source.tapFn,
        source.strategy,
        subscribe!(source.source, actor),
    )
end

function on_unsubscribe!(subscription::TapOnUnsubscribeSubscription)
    result = __on_unsubscribe_with_tap(subscription.strategy, subscription)
    subscription.is_unsubscribed = true
    return result
end

function __on_unsubscribe_with_tap(
    ::TapBeforeUnsubscription,
    subscription::TapOnUnsubscribeSubscription,
)
    if !subscription.is_unsubscribed
        subscription.tapFn()
    end
    return unsubscribe!(subscription.subscription)
end

function __on_unsubscribe_with_tap(
    ::TapAfterUnsubscription,
    subscription::TapOnUnsubscribeSubscription,
)
    result = unsubscribe!(subscription.subscription)
    if !subscription.is_unsubscribed
        subscription.tapFn()
    end
    return result
end

Base.show(io::IO, ::TapOnUnsubscribeOperator) = print(io, "TapOnUnsubscribeOperator()")
Base.show(io::IO, ::TapOnUnsubscribeProxy) = print(io, "TapOnUnsubscribeProxy()")
Base.show(io::IO, ::TapOnUnsubscribeSource{L}) where {L} =
    print(io, "TapOnUnsubscribeSource($L)")
Base.show(io::IO, ::TapOnUnsubscribeSubscription) =
    print(io, "TapOnUnsubscribeSubscription()")
