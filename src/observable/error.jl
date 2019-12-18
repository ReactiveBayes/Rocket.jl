export ErrorObservable, TypedErrorObservable, on_subscribe!, throwError

"""
    ErrorObservable{D}(error)

Observable that emits no items to the Actor and immediately emits an error notification on subscription.
"""
struct ErrorObservable{D} <: Subscribable{D}
    error
end

function on_subscribe!(observable::ErrorObservable{D}, actor::A) where { A <: AbstractActor{D} } where D
    error!(actor, observable.error)
    return VoidTeardown()
end

"""
    throwError(error, T = Any)

Creates an Observable that emits no items to the Actor and immediately emits an error notification.

# Arguments
- `error`: the particular Error to pass to the error notification.
- `T`: type of output data source, optional, `Any` is the default

# Examples

```jldoctest
using Rx

source = throwError("Error!")
subscribe!(source, LoggerActor{Any}())
;

# output

[LogActor] Error: Error!

```

See also: [`ErrorObservable`](@ref)
"""
throwError(error, T = Any) = ErrorObservable{T}(error)
