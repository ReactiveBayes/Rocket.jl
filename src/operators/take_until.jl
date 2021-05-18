export take_until

import Base: show

"""
    take_until(notifier::S)

Creates a take operator, which returns an Observable
that emits the values emitted by the source Observable until a `notifier` Observable emits a value or a completion event.

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

```julia
using Rocket 

source = interval(100)

subscribe!(source |> take_until(source |> filter(i -> i == 3)), logger())
;

# output 

[LogActor] Data: 0
[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Completed
```

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
take_until(notifier::N) where N = TakeUntilOperator{N}(notifier)

struct TakeUntilOperator{N} <: InferableOperator
    notifier :: N
end

function on_call!(::Type{L}, ::Type{L}, operator::TakeUntilOperator{N}, source) where { L, N }
    return proxy(L, source, TakeUntilProxy{N}(operator.notifier))
end

operator_right(operator::TakeUntilOperator, ::Type{L}) where L = L

struct TakeUntilProxy{N} <: SourceProxy
    notifier :: N
end

source_proxy!(::Type{L}, proxy::TakeUntilProxy{N}, source::S) where { L, N, S } = TakeUntilSource{L, N, S}(proxy.notifier, source)

mutable struct TakeUntilInnerActor{L, A} <: Actor{L}
    actor         :: A
    isdisposed    :: Bool
    ssubscription :: Teardown
    nsubscription :: Teardown

    TakeUntilInnerActor{L, A}(actor::A) where { L, A } = new(actor, false, voidTeardown, voidTeardown)
end

function on_next!(actor::TakeUntilInnerActor{L}, data::L) where L 
    if !actor.isdisposed
        next!(actor.actor, data)
    end
end

function on_error!(actor::TakeUntilInnerActor, err)
    if !actor.isdisposed
        __dispose(actor)
        error!(actor.actor, err)
    end
end

function on_complete!(actor::TakeUntilInnerActor)
    if !actor.isdisposed
        __dispose(actor)
        complete!(actor.actor)
    end
end

function __dispose(actor::TakeUntilInnerActor)
    actor.isdisposed = true
    unsubscribe!(actor.ssubscription)
    unsubscribe!(actor.nsubscription)
end

struct TakeUntilInnerActorGuard{I} <: Actor{Any}
    inner :: I
end

on_next!(guard::TakeUntilInnerActorGuard, _)    = complete!(guard.inner)
on_error!(guard::TakeUntilInnerActorGuard, err) = error!(guard.inner, err)
on_complete!(guard::TakeUntilInnerActorGuard)   = complete!(guard.inner)

@subscribable struct TakeUntilSource{L, N, S} <: Subscribable{L}
    notifier :: N
    source   :: S
end

function on_subscribe!(observable::TakeUntilSource{L}, actor::A) where { L, A }
    inner = TakeUntilInnerActor{L, A}(actor)
    guard = TakeUntilInnerActorGuard(inner)

    inner.nsubscription = subscribe!(observable.notifier, guard)

    if !inner.isdisposed
        inner.ssubscription = subscribe!(observable.source, inner)
        # Extra check for cases when __dispose has been called during main subscription
        if inner.isdisposed
            unsubscribe!(inner.ssubscription)
        end
    end

    return TakeUntilSubscription(inner)
end

struct TakeUntilSubscription{A} <: Teardown
    inner :: A
end

as_teardown(::Type{<:TakeUntilSubscription}) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::TakeUntilSubscription)
    __dispose(subscription.inner)
    return nothing
end


Base.show(io::IO, ::TakeUntilOperator)              = print(io, "TakeUntilOperator()")
Base.show(io::IO, ::TakeUntilProxy)                 = print(io, "TakeUntilProxy()")
Base.show(io::IO, ::TakeUntilInnerActor{L}) where L = print(io, "TakeUntilInnerActor($L)")
Base.show(io::IO, ::TakeUntilSource{L})     where L = print(io, "TakeUntilSource($L)")
Base.show(io::IO, ::TakeUntilSubscription)          = print(io, "TakeUntilSubscription()")
