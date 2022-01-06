export catch_error

import Base: show

"""
    catch_error(selectorFn::F) where F

Creates a `CatchErrorOperator`, which catches errors on the observable to be handled by returning a new observable or throwing an error.

# Arguments:
- `selectorFn::F`: a callable object that takes as arguments err, which is the error, and caught, which is the source observable, in case you'd like to "retry" that observable by returning it again. Whatever observable is returned by the selector will be used to continue the observable chain.

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream

# Examples
```jldoctest
using Rocket

source = from(1:5) |> safe() |> map(Int, (d) -> d == 4 ? error(4) : d) |> catch_error((err, obs) -> of(1))

subscribe!(source, logger())
;

# output
[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Data: 3
[LogActor] Data: 1
[LogActor] Completed
```

See also: [`Operator`](@ref), [`rerun`](@ref), [`logger`](@ref), [`safe`](@ref)
"""
catch_error(selectorFn::F) where F = CatchErrorOperator{F}(selectorFn)

struct CatchErrorOperator{F} <: Operator
    selectorFn :: F
end

operator_eltype(::CatchErrorOperator, ::Type{L}) where L = L

struct CatchErrorSubscribable{L, F, S} <: Subscribable{L}
    selectorFn :: F
    source     :: S
end

struct CatchErrorSubscription <: Subscription
    catch_error_actor :: Any
end

mutable struct CatchErrorActor{A, F}
    selectorFn           :: F
    actor                :: A
    is_completed         :: Bool
    current_source       :: Union{Nothing, Any}
    current_subscription :: Union{Nothing, Subscription}
end

function on_call!(::Type{L}, ::Type{L}, operator::CatchErrorOperator{F}, source::S) where { L, F, S }
    return CatchErrorSubscribable{L, F, S}(operator.selectorFn, source)
end

function on_subscribe!(source::CatchErrorSubscribable{L, F}, actor::A) where { L, F, A }
    catchactor = CatchErrorActor{A, F}(source.selectorFn, actor, false, nothing, nothing)
    catchactor.current_source       = source.source
    catchactor.current_subscription = subscribe!(source.source, catchactor)
    return CatchErrorSubscription(catchactor)
end

function on_unsubscribe!(subscription::CatchErrorSubscription)
    current_subscription = subscription.catch_error_actor.current_subscription
    subscription.catch_error_actor.current_source       = nothing
    subscription.catch_error_actor.current_subscription = nothing
    return unsubscribe!(current_subscription)
end

function on_next!(actor::CatchErrorActor, data)
    if !actor.is_completed
        next!(actor.actor, data)
    end
end

function on_error!(actor::CatchErrorActor, err)
    if !actor.is_completed
        if actor.current_subscription !== nothing
            unsubscribe!(actor.current_subscription)
        end

        fallback_source = actor.selectorFn(err, actor.current_source)

        actor.current_source       = fallback_source
        actor.current_subscription = subscribe!(fallback_source, actor)
    end
end

function on_complete!(actor::CatchErrorActor)
    if !actor.is_completed
        actor.is_completed = true
        complete!(actor.actor)
    end
end

Base.show(io::IO, ::CatchErrorOperator)                = print(io, "CatchErrorOperator()")
Base.show(io::IO, ::CatchErrorSubscribable{L}) where L = print(io, "CatchErrorSubscribable($L)")
Base.show(io::IO, ::CatchErrorSubscription)            = print(io, "CatchErrorSubscription()")
Base.show(io::IO, ::CatchErrorActor)                   = print(io, "CatchErrorActor()")

