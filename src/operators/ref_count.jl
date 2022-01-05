export ref_count

import Base: show

"""
    ref_count()

Makes the `ConnectableObservable` behave like an ordinary observable and automates the way you can connect to it.
Internally it counts the subscriptions to the observable and subscribes (only once) to the source if the number of subscriptions is larger than 0. If the number of subscriptions is smaller than 1, it unsubscribes from the source.
This way you can make sure that everything before the published `ref_count()` has only a single subscription independently of the number of subscribers to the target observable.

Note that using the [`share`](@ref) operator is exactly the same as using the [`publish`](@ref) operator (making the observable hot) and the [`ref_count()`](@ref) operator in a sequence.

# Example

```jldoctest
using Rocket

subject = Subject(Int, scheduler = AsapScheduler())
source  = from(1:5) |> multicast(subject) |> ref_count()

actor1 = logger("1")
actor2 = logger("2")

subscription1 = subscribe!(source, actor1)
subscription2 = subscribe!(source, actor2)

unsubscribe!(subscription1)
unsubscribe!(subscription2)
;

# output
[1] Data: 1
[1] Data: 2
[1] Data: 3
[1] Data: 4
[1] Data: 5
[1] Completed
[2] Completed
```

See also: [`Operator`](@ref), [`publish`](@ref), [`multicast`](@ref), [`share`](@ref)
"""
ref_count() = RefCountOperator()

struct RefCountOperator <: Operator end

operator_eltype(::RefCountOperator, ::Type{L}) where L = L

function on_call!(::Type{L}, ::Type{L}, operator::RefCountOperator, source::S) where { L, S }
    return RefCountSubscribable{L, S}(source)
end

mutable struct RefCountSubscribable{L, S} <: Subscribable{L}
    csource       :: S
    refcount      :: Int
    csubscription :: Subscription

    RefCountSubscribable{L, S}(csource::S) where { L, S } = new(csource, 0, noopSubscription)
end

function on_subscribe!(refsource::RefCountSubscribable, actor)
    subscription = subscribe!(refsource.csource, actor)
    refsource.refcount += 1
    if refsource.refcount === 1
        refsource.csubscription = connect(refsource.csource)
    end
    return RefCountSubscription(refsource, subscription)
end

mutable struct RefCountSubscription{S, T} <: Subscription
    refcount_source :: Union{Nothing, S}
    subscription    :: T
end

function on_unsubscribe!(subscription::RefCountSubscription)
    unsubscribe!(subscription.subscription)

    refcount_source = subscription.refcount_source
    if refcount_source !== nothing
        refcount_source.refcount -= 1
        if refcount_source.refcount === 0
            unsubscribe!(refcount_source.csubscription)
            refcount_source.csubscription = noopSubscription
        end
        subscription.refcount_source = nothing
    end
end

Base.show(io::IO, ::RefCountOperator)                = print(io, "RefCountOperator()")
Base.show(io::IO, ::RefCountSubscribable{L}) where L = print(io, "RefCountSubscribable($L)")
Base.show(io::IO, ::RefCountSubscription)            = print(io, "RefCountSubscription()")
