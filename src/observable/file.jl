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
    f = open(observable.path, "r")
    for line in eachline(f)
        next!(actor, line)
    end
    complete!(actor)
    close(f)
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
