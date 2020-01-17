export SyncFileObservable, on_subscribe!
export file

import Base: ==

"""
    SyncFileObservable(path::String)

File observable, which synchronously emits content of the file line by line as a `String` objects on subscription.

See also: [`file`](@ref), [`Subscribable`](@ref)
"""
struct SyncFileObservable <: Subscribable{String}
    path :: String
end

function on_subscribe!(observable::SyncFileObservable, actor)
    f = open(observable.path, "r")
    for line in eachline(f)
        next!(actor, line)
    end
    complete!(actor)
    close(f)
    return VoidTeardown()
end

"""
    file(path::String)

Helper function to creates a `SyncFileObservable` with a given path.

See also: [`SyncFileObservable`](@ref)
"""
file(path::String) = SyncFileObservable(path)

Base.:(==)(f1::SyncFileObservable, f2::SyncFileObservable) = f1.path == f2.path
