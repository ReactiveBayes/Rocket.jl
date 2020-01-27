export LambdaActor, lambda

"""
    LambdaActor{D}(; on_next = nothing, on_error = nothing, on_complete = nothing) where D

Lambda actor wraps `on_next`, `on_error`, `on_complete` callbacks for data, error and complete events.

# Constructor arguments
- `on_next`: Callback for data event. Optional. Default is `nothing`.
- `on_error`: Callback for error event. Optional. Default is `nothing`.
- `on_complete`: Callback for complete event. Optional. Default is `nothing`.

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

is_exhausted(actor::LambdaActor) = false

function on_next!(actor::LambdaActor{D}, data::D) where D
    if actor.on_next !== nothing
        actor.on_next(data)
    end
end

function on_error!(actor::LambdaActor, err)
    if actor.on_error !== nothing
        actor.on_error(err)
    end
end

function on_complete!(actor::LambdaActor)
    if actor.on_complete !== nothing
        actor.on_complete()
    end
end

struct LambdaActorFactory <: AbstractActorFactory
    on_next     :: Union{Nothing, Function}
    on_error    :: Union{Nothing, Function}
    on_complete :: Union{Nothing, Function}
end

function create_actor(::Type{L}, factory::LambdaActorFactory) where L
    return LambdaActor{L}(on_next = factory.on_next, on_error = factory.on_error, on_complete = factory.on_complete)
end

"""
    lambda(; on_next = nothing, on_error = nothing, on_complete = nothing)
    lambda(::Type{T}; on_next = nothing, on_error = nothing, on_complete = nothing) where T

Creation operator for the 'LambdaActor' actor.

# Examples

```jldoctest
using Rx

actor = lambda(Int; on_next = (d) -> println(d))
actor isa LambdaActor{Int}

# output
true
```

See also: [`LambdaActor`](@ref), [`AbstractActor`](@ref)
"""
lambda(; on_next = nothing, on_error = nothing, on_complete = nothing) = LambdaActorFactory(on_next, on_error, on_complete)
lambda(::Type{T}; on_next = nothing, on_error = nothing, on_complete = nothing) where T = LambdaActor{T}(on_next = on_next, on_error = on_error, on_complete = on_complete)
