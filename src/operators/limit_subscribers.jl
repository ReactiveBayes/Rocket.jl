export limit_subscribers, LimitSubscribersGuard

import Base: show
import DataStructures: isfull

"""
    LimitSubscribersGuard(limit::Int = 1, exclusive = true)

Guard structure used in `limit_subscribers` operator.

# Arguments
- `limit`: number of concurrent subscribers
- `exclusive`: boolean flag, which indicates whenever this guard can be shared with other observables in other `limit_subscribers` operator. If set to `true`, reusing this guard in a different `limit_subscribers` operator for other observable will result in automatic unsubscription of all present actors.

# Note
This structure is useful in Pluto.jl notebooks in particular, allowing for automatic subscription/unsubscription of observables.

# Example 

```julia

# Cell 1
guard = LimitSubscribersGuard()

# Cell 2
subscription = subscribe!(some_stream |> limit_subscribers(guard), logger())
```

See also: [`limit_subscribers`](@ref), [`subscribe!`](@ref)
"""
struct LimitSubscribersGuard 
    limit     :: Int
    exclusive :: Bool
    handlers  :: CircularBuffer{Tuple{Teardown, Any}}
end

LimitSubscribersGuard(limit::Int = 1, exclusive::Bool = true) = LimitSubscribersGuard(limit, exclusive, CircularBuffer{Tuple{Teardown, Any}}(limit))

Base.show(io::IO, guard::LimitSubscribersGuard) = print(io, "LimitSubscribersGuard($(getlimit(guard)), $(isexclusive(guard)))")

getlimit(guard::LimitSubscribersGuard)    = guard.limit
isexclusive(guard::LimitSubscribersGuard) = guard.exclusive
gethandlers(guard::LimitSubscribersGuard) = guard.handlers

function unsubscribe_last!(guard::LimitSubscribersGuard)
    if !isempty(gethandlers(guard))
        subscription, actor = popfirst!(gethandlers(guard))
        complete!(actor)
        unsubscribe!(subscription)
    end
    return nothing
end

function remove_handler!(guard::LimitSubscribersGuard, subscription)
    f = filter(d -> first(d) !== subscription, gethandlers(guard))
    if length(f) !== length(gethandlers(guard))
        empty!(gethandlers(guard))
        append!(gethandlers(guard), f)
    end
    return nothing
end

function add_subscription!(guard::LimitSubscribersGuard, subscription::Teardown, actor)
    if isfull(gethandlers(guard))
        unsubscribe_last!(guard)
    end
    push!(gethandlers(guard), (subscription, actor))
    return subscription
end

function release!(guard::LimitSubscribersGuard)
    foreach(gethandlers(guard)) do handler
        subscription, actor = handler
        complete!(actor)
        unsubscribe!(subscription)
    end
    empty!(gethandlers(guard))
    return nothing
end

"""
    limit_subscribers(limit::Int = 1, exclusive::Bool = true)
    limit_subscribers(guard::LimitSubscribersGuard)

Creates an operator that limits number of concurrent actors to the given observable. On new subscription, if limit is exceeded, oldest actor is automatically unsubscribed and receives a completion event.

# Arguments
- `limit`: number of concurrent subscribers
- `exclusive`: boolean flag, which indicates whenever this guard can be shared with other observables in other `limit_subscribers` operator. If set to `true`, reusing this guard in a different `limit_subscribers` operator for other observable will result in automatic unsubscription of all present actors.

# Note
This structure is useful in Pluto.jl notebooks in particular, allowing for automatic subscription/unsubscription of observables.

# Example 

```julia

# Cell 1
guard = LimitSubscribersGuard()

# Cell 2
subscription = subscribe!(some_stream |> limit_subscribers(guard), logger())
```

See also: [`LimitSubscribersGuard`](@ref)
"""
limit_subscribers(limit::Int = 1, exclusive::Bool = true) = limit_subscribers(LimitSubscribersGuard(limit, exclusive))
limit_subscribers(guard::LimitSubscribersGuard)           = LimitSubscribersOperator(guard)

struct LimitSubscribersOperator <: InferableOperator 
    guard :: LimitSubscribersGuard
end

operator_right(::LimitSubscribersOperator, ::Type{L}) where L = L

function on_call!(::Type{L}, ::Type{L}, operator::LimitSubscribersOperator, source) where L
    if isexclusive(operator.guard)
        release!(operator.guard)
    end
    return proxy(L, source, LimitSubscribersProxy(operator.guard))
end

struct LimitSubscribersProxy <: SourceProxy 
    guard :: LimitSubscribersGuard
end

source_proxy!(::Type{L}, proxy::LimitSubscribersProxy, source::S) where { L, S } = LimitSubscribersSource{L, S}(source, proxy.guard)

struct LimitSubscribersSubscription{S} <: Teardown
    subscription :: S
    guard        :: LimitSubscribersGuard
end

as_teardown(::Type{ <: LimitSubscribersSubscription }) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::LimitSubscribersSubscription)
    remove_handler!(subscription.guard, subscription.subscription)
    unsubscribe!(subscription.subscription)
    return nothing
end

struct LimitSubscribersSource{L, S} <: Subscribable{L}
    source :: S
    guard  :: LimitSubscribersGuard
end

function on_subscribe!(source::LimitSubscribersSource, actor)
    guard = source.guard
    if isfull(gethandlers(guard))
        unsubscribe_last!(guard)
    end
    return LimitSubscribersSubscription(add_subscription!(guard, subscribe!(source.source, actor), actor), guard)
end

Base.show(io::IO, ::LimitSubscribersOperator)          = print(io, "LimitSubscribersOperator()")
Base.show(io::IO, ::LimitSubscribersProxy)             = print(io, "LimitSubscribersProxy()")
Base.show(io::IO, ::LimitSubscribersSource{L}) where L = print(io, "LimitSubscribersSource($L)")
Base.show(io::IO, ::LimitSubscribersSubscription)      = print(io, "LimitSubscribersSubscription()")
