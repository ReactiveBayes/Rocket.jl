export SyncFileObservable, file

import Base: ==
import Base: show

"""
    SyncFileObservable(path::String)

File observable, which synchronously emits content of the file line by line as a `String` objects on subscription.

See also: [`file`](@ref), [`Subscribable`](@ref)
"""
struct SyncFileObservable <: Subscribable{String}
    path::String
end

function on_subscribe!(observable::SyncFileObservable, actor)
    # Deliver an open failure (missing file / permissions) via `error!` instead of letting
    # it propagate raw out of `on_subscribe!`, and always close the handle (issue #79).
    local f
    try
        f = open(observable.path, "r")
    catch err
        error!(actor, err)
        return voidTeardown
    end
    try
        for line in eachline(f)
            next!(actor, line)
        end
        complete!(actor)
    catch err
        error!(actor, err)
    finally
        close(f)
    end
    return voidTeardown
end

"""
    file(path::String)

Creation operator for the `SyncFileObservable` with a given path.

See also: [`SyncFileObservable`](@ref)
"""
file(path::String) = SyncFileObservable(path)

Base.:(==)(f1::SyncFileObservable, f2::SyncFileObservable) = f1.path == f2.path

Base.show(io::IO, observable::SyncFileObservable) = print(io, "SyncFileObservable()")
