export RefCountOperator, on_call!, operator_right
export RefCountProxy, source_proxy!
export RefCountSource, connect_source!, disconnect_source!, on_subscribe!
export RefCountSourceSubscription, as_teardown, on_unsubscribe!

export ref_count

ref_count() = RefCountOperator()

struct RefCountOperator <: InferableOperator end

function on_call!(::Type{L}, ::Type{L}, operator::RefCountOperator, source) where L
    return ProxyObservable{L}(source, RefCountProxy{L}())
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
