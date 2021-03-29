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

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`rerun`](@ref), [`logger`](@ref), [`safe`](@ref)
"""
catch_error(selectorFn::F) where F = CatchErrorOperator{F}(selectorFn)

struct CatchErrorOperator{F} <: InferableOperator
    selectorFn :: F
end

function on_call!(::Type{L}, ::Type{L}, operator::CatchErrorOperator{F}, source) where { L, F }
    return proxy(L, source, CatchErrorProxy{F}(operator.selectorFn))
end

operator_right(operator::CatchErrorOperator, ::Type{L}) where L = L

struct CatchErrorProxy{F} <: ActorSourceProxy
    selectorFn :: F
end

actor_proxy!(::Type{L}, proxy::CatchErrorProxy{F},  actor::A)  where { L, A, F } = CatchErrorActor{L, A, F}(proxy.selectorFn, actor, false, nothing, nothing)
source_proxy!(::Type{L}, proxy::CatchErrorProxy{F}, source::S) where { L, S, F } = CatchErrorSource{L, S}(source)

mutable struct CatchErrorActor{L, A, F} <: Actor{L}
    selectorFn           :: F
    actor                :: A
    is_completed         :: Bool
    current_source       :: Union{Nothing, Any}
    current_subscription :: Union{Nothing, Teardown}
end

function on_next!(actor::CatchErrorActor{L}, data::L) where L
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

@subscribable struct CatchErrorSource{L, S} <: Subscribable{L}
    source :: S
end

struct CatchErrorSubscription <: Teardown
    catch_error_actor
end

as_teardown(::Type{<:CatchErrorSubscription}) = UnsubscribableTeardownLogic()

function on_subscribe!(source::CatchErrorSource, actor::CatchErrorActor)
    actor.current_source       = source.source
    actor.current_subscription = subscribe!(source.source, actor)

    return CatchErrorSubscription(actor)
end

function on_unsubscribe!(subscription::CatchErrorSubscription)
    current_subscription = subscription.catch_error_actor.current_subscription

    subscription.catch_error_actor.current_source       = nothing
    subscription.catch_error_actor.current_subscription = nothing

    return unsubscribe!(current_subscription)
end

Base.show(io::IO, ::CatchErrorOperator)             = print(io, "CatchErrorOperator()")
Base.show(io::IO, ::CatchErrorProxy)                = print(io, "CatchErrorProxy()")
Base.show(io::IO, ::CatchErrorActor{L})     where L = print(io, "CatchErrorActor($L)")
Base.show(io::IO, ::CatchErrorSource{L})    where L = print(io, "CatchErrorSource($L)")
Base.show(io::IO, ::CatchErrorSubscription)         = print(io, "CatchErrorSubscription()")
