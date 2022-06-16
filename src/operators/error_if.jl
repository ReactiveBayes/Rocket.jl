export error_if

import Base: show

"""
    error_if(checkFn, errorFn) 

Creates an `error_if` operator, which performs a check for every emission on the source Observable with `checkFn`. 
If `checkFn` returns `true`, the operator sends an `error` event and unsubscribes from the observable.

# Arguments
- `checkFn`: check function with `(data) -> Bool` signature
- `errorFn`: error object generating function with `(data) -> Any` signature, optional

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream

# Examples
```jldoctest
using Rocket

source = from([1, 2, 3]) |> error_if((data) -> data > 2, (data) -> "CustomError")

subscription = subscribe!(source, lambda(
    on_next  = (d) -> println("Next: ", d),
    on_error = (e) -> println("Error: ", e),
    on_complete = () -> println("Completed")
));

# output
Next: 1
Next: 2
Error: CustomError
```

See also: [`error_if_not`](@ref), [`error_if_empty`](@ref), [`default_if_empty`](@ref), [`lambda`](@ref)
"""
error_if(checkFn::F, errorFn::E = nothing) where { F, E } = ErrorIfOperator{F, E}(checkFn, errorFn)

struct ErrorIfOperator{F, E} <: InferableOperator
    checkFn :: F
    errorFn :: E
end

function on_call!(::Type{L}, ::Type{L}, operator::ErrorIfOperator{F, E}, source) where { L, F, E }
    return proxy(L, source, ErrorIfProxy{F, E}(operator.checkFn, operator.errorFn))
end

operator_right(::ErrorIfOperator, ::Type{L}) where L = L

struct ErrorIfProxy{F, E} <: ActorSourceProxy
    checkFn :: F
    errorFn :: E
end

actor_proxy!(::Type{L}, proxy::ErrorIfProxy{F, E}, actor::A) where { L, A, F, E } = ErrorIfActor{L, A, F, E}(proxy.checkFn, proxy.errorFn, actor, false, voidTeardown)
source_proxy!(::Type{L}, proxy::ErrorIfProxy, source::S) where { L, S } = ErrorIfSource{L, S}(source)

mutable struct ErrorIfActor{L, A, F, E} <: Actor{L}
    checkFn :: F
    errorFn :: E
    actor :: A
    completed::Bool
    subscription
end

error_msg(actor::ErrorIfActor, data) = error_msg(actor, actor.errorFn, data)

error_msg(::ErrorIfActor, ::Nothing, data) = "`error_if` operator check failed for data $(data)"
error_msg(::ErrorIfActor, callback, data)  = callback(data)

function on_next!(actor::ErrorIfActor{L}, data::L) where L 
    if !actor.completed
        check = actor.checkFn(data)
        if check 
            error!(actor, error_msg(actor, data))
        else 
            next!(actor.actor, data)
        end
    end
end

function on_error!(actor::ErrorIfActor, err) 
    if !actor.completed 
        actor.completed = true
        unsubscribe!(actor.subscription)
        error!(actor.actor, err)
    end
end

function on_complete!(actor::ErrorIfActor) 
    if !actor.completed 
        actor.completed = true
        complete!(actor.actor)
    end
end

@subscribable struct ErrorIfSource{L, S} <: Subscribable{L}
    source :: S
end

function on_subscribe!(source::ErrorIfSource, actor::ErrorIfActor)
    subscription = subscribe!(source.source, actor)
    if !actor.completed
        actor.subscription = subscription
    end
    return subscription
end

Base.show(io::IO, ::ErrorIfOperator)          = print(io, "ErrorIfOperator()")
Base.show(io::IO, ::ErrorIfProxy)             = print(io, "ErrorIfProxy()")
Base.show(io::IO, ::ErrorIfActor{L}) where L  = print(io, "ErrorIfActor($L)")
Base.show(io::IO, ::ErrorIfSource{L}) where L = print(io, "ErrorIfSource($L)")
