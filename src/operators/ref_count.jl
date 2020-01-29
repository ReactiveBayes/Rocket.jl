export RefCountOperator, on_call!, operator_right
export RefCountProxy, source_proxy!
export RefCountSource, connect_source!, disconnect_source!, on_subscribe!
export RefCountSourceSubscription, as_teardown, on_unsubscribe!
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
using Rx

subject = make_subject(Int, mode = SYNCHRONOUS_SUBJECT_MODE)
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
    return proxy(L, source, RefCountProxy{L}())
end

operator_right(operator::RefCountOperator, ::Type{L}) where L = L

struct RefCountProxy{L} <: SourceProxy end

source_proxy!(proxy::RefCountProxy{L}, connectable_source) where L = RefCountSource{L}(connectable_source)

mutable struct RefCountSource{L} <: Subscribable{L}
    ref_count
    connectable_source
    connectable_subscription :: Union{Nothing, Teardown}

    RefCountSource{L}(connectable_source) where L = new(0, connectable_source, nothing)
end

function connect_source!(ref_count_source::RefCountSource)
    if ref_count_source.ref_count > 0 && ref_count_source.connectable_subscription === nothing
        ref_count_source.connectable_subscription = connect(ref_count_source.connectable_source)
    end
end

function disconnect_source!(ref_count_source::RefCountSource)
    unsubscribe!(ref_count_source.connectable_subscription)
    ref_count_source.connectable_subscription = nothing
end

function on_subscribe!(ref_count_source::RefCountSource, actor)
    subscription = subscribe!(ref_count_source.connectable_source, actor)
    ref_count_source.ref_count += 1
    if ref_count_source.ref_count == 1
        connect_source!(ref_count_source)
    end
    return _ref_count_subscription(ref_count_source, subscription)
end

mutable struct RefCountSourceSubscription{T} <: Teardown
    ref_count_source :: Union{Nothing, RefCountSource}
    subscription     :: T
end

_ref_count_subscription(ref_count_source::RefCountSource, subscription::T) where T = RefCountSourceSubscription{T}(ref_count_source, subscription)

as_teardown(::Type{<:RefCountSourceSubscription}) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::RefCountSourceSubscription)
    unsubscribe!(subscription.subscription)
    if subscription.ref_count_source !== nothing
        subscription.ref_count_source.ref_count -= 1
        if subscription.ref_count_source.ref_count == 0 && subscription.ref_count_source.connectable_subscription !== nothing
            disconnect_source!(subscription.ref_count_source)
        end
        subscription.ref_count_source = nothing
    end
end

Base.show(io::IO, operator::RefCountOperator)         = print(io, "RefCountOperator()")
Base.show(io::IO, proxy::RefCountProxy{L})    where L = print(io, "RefCountProxy($L)")
Base.show(io::IO, source::RefCountSource{L})  where L = print(io, "RefCountSource($L)")
Base.show(io::IO, subscription::RefCountSourceSubscription) = print("RefCountSourceSubscription()")
