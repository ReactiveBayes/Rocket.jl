export NoopSubscription, noopSubscription

"""
    NoopSubscription()

`NoopSubscription` object does nothing on unsubscription.
It is usefull for synchronous observables and observables which cannot be cancelled after start of their execution.

See also: [`Subscription`](@ref), [`unsubscribe!`](@ref)
"""
struct NoopSubscription <: Subscription end

"""
    noopSubscription

An instance of `NoopSubscription` singleton object.

See also: [`NoopSubscription`](@ref), [`unsubscribe!`](@ref)
"""
const noopSubscription = NoopSubscription()

on_unsubscribe!(::NoopSubscription) = begin end
