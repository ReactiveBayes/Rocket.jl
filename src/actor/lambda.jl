export LambdaActor, on_next!, on_error!, on_complete!

"""
    LambdaActor{D}(; on_next = nothing, on_error = nothing, on_complete = nothing) where D

Lambda actors wraps `on_next`, `on_error`, `on_complete` callbacks for data, error and complete events processing and can be useful for debugging.

# Constructor arguments
- `on_next`: Callback for data event, optional
- `on_error`: Callback for error event, optional
- `on_complete`: Callback for complete event, optional

# Examples

```jldoctest
using Rx

source = from([ 0, 1, 2 ])
subscribe!(source, LambdaActor{Int}(
    on_next = (d) -> println("Data event: \$d")
))
;

# output

Data event: 0
Data event: 1
Data event: 2

```

```jldoctest
using Rx

source = from([ 0, 1, 2 ])
subscribe!(source, LambdaActor{Int}(
    on_complete = () -> println("Completed")
));
;

# output

Completed

```

See also: [`Actor`](@ref)
"""
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

function on_error!(actor::LambdaActor{D}, err) where D
    if actor.on_error != nothing
        Base.invokelatest(actor.on_error, err)
    end
end

function on_complete!(actor::LambdaActor{D}) where D
    if actor.on_complete != nothing
        Base.invokelatest(actor.on_complete)
    end
end
