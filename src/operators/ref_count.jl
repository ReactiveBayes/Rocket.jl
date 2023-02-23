export ref_count

import Base: show

"""
    ref_count()

Make a ConnectableObservable behave like a ordinary observable and automates the way you can connect to it.
Internally it counts the subscriptions to the observable and subscribes (only once) to the source if the number of subscriptions is larger than 0. If the number of subscriptions is smaller than 1, it unsubscribes from the source.
This way you can make sure that everything before the published refCount has only a single subscription independently of the number of subscribers to the target observable.

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

See also: [`AbstractOperator`](@ref), [`publish`](@ref), [`multicast`](@ref), [`share`](@ref)
"""
ref_count() = RefCountOperator()

struct RefCountOperator <: InferableOperator end

function on_call!(::Type{L}, ::Type{L}, operator::RefCountOperator, source) where L
    return proxy(L, source, RefCountProxy())
end

operator_right(operator::RefCountOperator, ::Type{L}) where L = L

struct RefCountProxy <: SourceProxy end

source_proxy!(::Type{L}, proxy::RefCountProxy, source::S) where { L, S } = RefCountSource{L, S}(source)

@subscribable mutable struct RefCountSource{L, S} <: Subscribable{L}
    csource       :: S
    refcount      :: Int
    csubscription :: Teardown

    RefCountSource{L, S}(csource::S) where { L, S } = new(csource, 0, voidTeardown)
end

getrecent(source::RefCountSource, ::RefCountProxy) = getrecent(source.csource)

function on_subscribe!(refcount_source::RefCountSource, actor)
    subscription = subscribe!(refcount_source.csource, actor)
    refcount_source.refcount += 1
    if refcount_source.refcount === 1
        refcount_source.csubscription = connect(refcount_source.csource)
    end
    return RefCountSourceSubscription(refcount_source, subscription)
end

mutable struct RefCountSourceSubscription{S, T} <: Teardown
    refcount_source :: Union{Nothing, S}
    subscription    :: T
end

as_teardown(::Type{<:RefCountSourceSubscription}) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::RefCountSourceSubscription)
    unsubscribe!(subscription.subscription)

    refcount_source = subscription.refcount_source
    if refcount_source !== nothing
        refcount_source.refcount -= 1
        if refcount_source.refcount === 0
            unsubscribe!(refcount_source.csubscription)
            refcount_source.csubscription = voidTeardown
        end
        subscription.refcount_source = nothing
    end
end

Base.show(io::IO, ::RefCountOperator)           = print(io, "RefCountOperator()")
Base.show(io::IO, ::RefCountProxy)              = print(io, "RefCountProxy()")
Base.show(io::IO, ::RefCountSource{L})  where L = print(io, "RefCountSource($L)")
Base.show(io::IO, ::RefCountSourceSubscription) = print(io, "RefCountSubscription()")
