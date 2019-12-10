export LambdaActor, on_next!, on_error!, on_complete!

struct LambdaActor{D} <: Actor{D}
    next     :: Union{Nothing, Function}
    error    :: Union{Nothing, Function}
    complete :: Union{Nothing, Function}

    LambdaActor{D}(; next = nothing, error = nothing, complete = nothing) where D = new(next, error, complete)
end

function on_next!(actor::LambdaActor{D}, data::D) where D
    if actor.next != nothing
        actor.next(data)
    end
end

function on_error!(actor::LambdaActor{D}, error) where D
    if actor.error != nothing
        actor.error(error)
    end
end

function on_complete!(actor::LambdaActor{D}) where D
    if actor.complete != nothing
        actor.complete()
    end
end
