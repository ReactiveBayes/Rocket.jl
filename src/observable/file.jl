export FileObservable, on_subscribe!, file, file_async

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

struct AsyncFileObservable <: Subscribable{String}
    path :: String
end

function on_subscribe!(observable::AsyncFileObservable, actor)
    error("AsyncFileObservable not implemented yet.")
end

"""
    file(path::String)

Creates a file observable which emits line by line synchronously
"""
file(path::String)       = SyncFileObservable(path)
file_async(path::String) = AsyncFileObservable(path)
