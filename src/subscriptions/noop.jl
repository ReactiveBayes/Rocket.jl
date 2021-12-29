export VoidTeardown, voidTeardown

import Base: ==

"""
    NoopSubscription()

`NoopSubscription` object does nothing on unsubscription.
It is usefull for synchronous observables and observables which cannot be cancelled after start of their execution.

See also: [`AbstractSubscription`](@ref), [`unsubscribe!`](@ref)
"""
struct NoopSubscription <: Subscription end

"""
    noopSubscription

An instance of `NoopSubscription` singleton object.

See also: [`NoopSubscription`](@ref), [`unsubscribe!`](@ref)
"""
const noopSubscription = NoopSubscription()

unsubscribe!(::NoopSubscription) = begin end
