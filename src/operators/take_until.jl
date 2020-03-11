export take_until

import Base: show

"""
    take_until(notifier::S)

Creates a take operator, which returns an Observable
that emits the values emitted by the source Observable until a `notifier` Observable emits a value.

# Arguments
- `notifier::S`: The Observable whose first emitted value will cause the output Observable of `take_until` to stop emitting values from the source Observable.

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream

# Examples

```julia
using Rocket

source = interval(100) |> take_until(timer(1000))

subscribe!(source, logger())
;

# output

[LogActor] Data: 0
[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Data: 3
[LogActor] Data: 4
[LogActor] Data: 5
[LogActor] Data: 6
[LogActor] Data: 7
[LogActor] Data: 8
[LogActor] Completed
```

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
take_until(notifier::N) where N = TakeUntilOperator{N}(notifier)

struct TakeUntilOperator{N} <: InferableOperator
    notifier :: N
end

function on_call!(::Type{L}, ::Type{L}, operator::TakeUntilOperator{N}, source) where { L, N }
    return proxy(L, source, TakeUntilProxy{L, N}(operator.notifier))
end

operator_right(operator::TakeUntilOperator, ::Type{L}) where L = L

struct TakeUntilProxy{L, N} <: SourceProxy
    notifier :: N
end

source_proxy!(proxy::TakeUntilProxy{L, N}, source::S) where { L, N, S } = TakeUntilSource{L, N, S}(proxy.notifier, source)

mutable struct TakeUntilInnerActor{L, A} <: Actor{L}
    is_completed  :: Bool
    actor         :: A
    subscription

    TakeUntilInnerActor{L, A}(actor::A) where { L, A } = begin
        self = new()
        self.is_completed = false
        self.actor        = actor
        return self
    end
end

is_exhausted(actor::TakeUntilInnerActor) = actor.is_completed || is_exhausted(actor.actor)

on_next!(actor::TakeUntilInnerActor{L}, data::L) where L = next!(actor.actor, data)

function on_error!(actor::TakeUntilInnerActor, err)
    error!(actor.actor, err)
    if isdefined(actor, :subscription)
        unsubscribe!(actor.subscription)
    end
    actor.is_completed = true
end

function on_complete!(actor::TakeUntilInnerActor)
    complete!(actor.actor)
    if isdefined(actor, :subscription)
        unsubscribe!(actor.subscription)
    end
    actor.is_completed = true
end

struct TakeUntilSource{L, N, S} <: Subscribable{L}
    notifier :: N
    source   :: S
end

function on_subscribe!(observable::TakeUntilSource{L}, actor::A) where { L, A }
    inner_actor  = TakeUntilInnerActor{L, A}(actor)

    source_subscription   = subscribe!(observable.source, inner_actor)
    notifier_subscription = VoidTeardown()

    if !is_exhausted(inner_actor)
        notifier_subscription    = subscribe!(observable.notifier |> take(1), _ -> begin
            unsubscribe!(source_subscription)
            if !is_exhausted(inner_actor)
                complete!(inner_actor)
            end
        end)
        inner_actor.subscription = notifier_subscription
    end

    return TakeUntilSubscription(source_subscription, notifier_subscription)
end

struct TakeUntilSubscription{S1, S2} <: Teardown
    source_subscription   :: S1
    notifier_subscription :: S2
end

as_teardown(::Type{<:TakeUntilSubscription}) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::TakeUntilSubscription)
    unsubscribe!(subscription.source_subscription)
    unsubscribe!(subscription.notifier_subscription)
    return nothing
end


Base.show(io::IO, operator::TakeUntilOperator)           = print(io, "TakeUntilOperator()")
Base.show(io::IO, proxy::TakeUntilProxy{L})      where L = print(io, "TakeUntilProxy($L)")
Base.show(io::IO, actor::TakeUntilInnerActor{L}) where L = print(io, "TakeUntilInnerActor($L)")
Base.show(io::IO, source::TakeUntilSource{L})    where L = print(io, "TakeUntilSource($L)")
Base.show(io::IO, source::TakeUntilSubscription)         = print(io, "TakeUntilSubscription()")
