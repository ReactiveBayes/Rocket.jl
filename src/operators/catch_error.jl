export catch_error

import Base: show

"""
    catch_error(selectorFn::Function)

Creates a `CatchErrorOperator`, which catches errors on the observable to be handled by returning a new observable or throwing an error.

# Arguments:
- `selectorFn::Function`: a function that takes as arguments err, which is the error, and caught, which is the source observable, in case you'd like to "retry" that observable by returning it again. Whatever observable is returned by the selector will be used to continue the observable chain.

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
catch_error(selectorFn::Function) = CatchErrorOperator(selectorFn)

struct CatchErrorOperator <: InferableOperator
    selectorFn :: Function
end

function on_call!(::Type{L}, ::Type{L}, operator::CatchErrorOperator, source) where L
    return proxy(L, source, CatchErrorProxy{L}(operator.selectorFn))
end

operator_right(operator::CatchErrorOperator, ::Type{L}) where L = L

struct CatchErrorProxy{L} <: ActorSourceProxy
    selectorFn :: Function
end

actor_proxy!(proxy::CatchErrorProxy{L},  actor::A)  where L where A = CatchErrorActor{L, A}(proxy.selectorFn, actor, false, nothing, nothing)
source_proxy!(proxy::CatchErrorProxy{L}, source::S) where L where S = CatchErrorSource{L, S}(source)

mutable struct CatchErrorActor{L, A} <: Actor{L}
    selectorFn           :: Function
    actor                :: A

    is_completed         :: Bool
    current_source       :: Union{Nothing, Any}
    current_subscription :: Union{Nothing, Teardown}
end

is_exhausted(actor::CatchErrorActor) = is_exhausted(actor.actor)

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

struct CatchErrorSource{L, S} <: Subscribable{L}
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

Base.show(io::IO, operator::CatchErrorOperator)                 = print(io, "CatchErrorOperator()")
Base.show(io::IO, proxy::CatchErrorProxy{L})            where L = print(io, "CatchErrorProxy($L)")
Base.show(io::IO, actor::CatchErrorActor{L})            where L = print(io, "CatchErrorActor($L)")
Base.show(io::IO, source::CatchErrorSource{L})          where L = print(io, "CatchErrorSource($L)")
Base.show(io::IO, subscription::CatchErrorSubscription)         = print(io, "CatchErrorSubscription()")
