export ErrorObservable, throwError

import Base: ==

"""
    ErrorObservable{D}(err)

    Observable that emits no items to the Actor and immediately sends an error notification on subscription.

    See also: [`throwError`](@ref)
"""
struct ErrorObservable{D} <: Subscribable{D}
    err
end

function on_subscribe!(observable::ErrorObservable, actor)
    error!(actor, observable.err)
    return VoidTeardown()
end

"""
    throwError(error, T = Any)

    Creation operator for the `ErrorObservable` that emits no items to the Actor and immediately sends an error notification.

    # Arguments
    - `error`: the particular Error to pass to the error notification.
    - `T`: type of output data source, optional, `Any` is the default

    # Examples

    ```jldoctest
    using Rocket

    source = throwError("Error!")
    subscribe!(source, logger())
    ;

    # output

    [LogActor] Error: Error!

    ```

    See also: [`ErrorObservable`](@ref), [`subscribe!`](@ref)
"""
throwError(err, T = Any) = ErrorObservable{T}(err)

Base.:(==)(e1::ErrorObservable{D},  e2::ErrorObservable{D})  where D           = e1.err == e2.err
Base.:(==)(e1::ErrorObservable{D1}, e2::ErrorObservable{D2}) where D1 where D2 = false
