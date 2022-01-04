export LazyObservable, lazy, set!

import Base: show

# TODO: Untested and undocumented
lazy(::Type{T} = Any) where T = LazyObservable{T}(Vector{Tuple{LazySubscription, Any}}(), nothing)

# Lazy subscription represents a reference to an original subscription or a lazy observable
mutable struct LazySubscription <: Subscription
    subscription_or_lazy :: Any
end

mutable struct LazyObservable{D} <: Subscribable{D}
    pending :: Vector{Tuple{LazySubscription, Any}}
    stream  :: Any
end

Base.show(io::IO, ::Type{ <: LazySubscription }) = print(io, "LazySubscription")
Base.show(io::IO, ::Type{ <: LazyObservable })   = print(io, "LazyObservable")

Base.show(io::IO, ::LazySubscription)           = print(io, "LazySubscription()")
Base.show(io::IO, ::LazyObservable{D}) where D  = print(io, "LazyObservable($D)")

getpending(lazy::LazyObservable) = lazy.pending
pushpending!(lazy::LazyObservable, subscription::LazySubscription, actor) = push!(lazy.pending, (subscription, actor))

getstream(lazy::LazyObservable)          = lazy.stream
setstream!(lazy::LazyObservable, stream) = lazy.stream = stream

@inline set!(lazy::LazyObservable, observable::S) where S = on_lazy_set!(lazy, eltype(S), observable)

@inline on_lazy_set!(lazy::LazyObservable{D1}, ::Type{D2}, observable) where { D1, D2 }       = error("Invalid usage of LazyObservable. Cannot set a stream of type $(D2) to a lazy observable of type $(D1).")
@inline on_lazy_set!(lazy::LazyObservable{D1}, ::Type{D2}, observable) where { D1, D2 <: D1 } = _on_lazy_set!(lazy, observable)

@inline function _on_lazy_set!(lazy, observable)

    if getstream(lazy) !== nothing
        error("Lazy stream cannot be set twice")
    end

    setstream!(lazy, observable)

    foreach(lazy.pending) do (subscription, actor)
        subscription.subscription_or_lazy = subscribe!(observable, actor)
    end

    empty!(lazy.pending)
    resize!(lazy.pending, 0)

    return nothing
end

function on_subscribe!(observable::LazyObservable, actor)
    stream = getstream(observable)
    if stream !== nothing
        return LazySubscription(subscribe!(stream, actor))
    else
        subscription = LazySubscription(observable)
        pushpending!(observable, subscription, actor)
        return subscription
    end
end

function on_unsubscribe!(subscription::LazySubscription)
    return unsubscribe_lazy!(subscription, subscription.subscription_or_lazy)
end

function unsubscribe_lazy!(subscription::LazySubscription, observable::LazyObservable)
    filter!(p -> first(p) !== subscription, observable.pending)
    return nothing
end

function unsubscribe_lazy!(::LazySubscription, subscription::Any)
    return unsubscribe!(subscription)
end
