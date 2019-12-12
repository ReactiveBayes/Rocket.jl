export LambdaActor, on_next!, on_error!, on_complete!

struct LambdaActor{D} <: Actor{D}
    on_next     :: Union{Nothing, Function}
    on_error    :: Union{Nothing, Function}
    on_complete :: Union{Nothing, Function}

    LambdaActor{D}(; on_next = nothing, on_error = nothing, on_complete = nothing) where D = new(on_next, on_error, on_complete)
end

function on_next!(actor::LambdaActor{D}, data::D) where D
    if actor.on_next != nothing
        Base.invokelatest(actor.on_next, data)
    end
end

function on_error!(actor::LambdaActor{D}, error) where D
    if actor.on_error != nothing
        Base.invokelatest(actor.on_error, error)
    end
end

function on_complete!(actor::LambdaActor{D}) where D
    if actor.on_complete != nothing
        Base.invokelatest(actor.on_complete)
    end
end
