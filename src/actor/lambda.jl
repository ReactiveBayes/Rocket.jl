export LambdaActor, lambda

"""
    LambdaActor{N, E, C}(on_next::N, on_error::E, on_complete::C)

Lambda actor wraps `on_next`, `on_error`, `on_complete` callbacks for data, error and complete events.
Should not be used explicitly, use [`lambda`](@ref) creation operator instead.

# Constructor arguments
- `on_next`: Callback for data event. Optional. Default is `nothing`.
- `on_error`: Callback for error event. Optional. Default is `nothing`.
- `on_complete`: Callback for complete event. Optional. Default is `nothing`.

See also: [`lambda`](@ref)
"""
struct LambdaActor{NextCallback, ErrorCallback, CompleteCallback}
    on_next     :: NextCallback
    on_error    :: ErrorCallback
    on_complete :: CompleteCallback
end

function on_next!(actor::LambdaActor, data)
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

struct LambdaActorFactory{NextCallback, ErrorCallback, CompleteCallback} <: AbstractActorFactory
    on_next     :: NextCallback
    on_error    :: ErrorCallback
    on_complete :: CompleteCallback
end

function create_actor(::Type{L}, factory::LambdaActorFactory{N, E, C}) where { L, N, E, C }
    return LambdaActor{N, E, C}(factory.on_next, factory.on_error, factory.on_complete)
end

"""
    lambda(; on_next = nothing, on_error = nothing, on_complete = nothing)
    lambda(::Type{T}; on_next = nothing, on_error = nothing, on_complete = nothing) where T

Creation operator for the 'LambdaActor' actor.

# Examples

```jldoctest
using Rocket

actor = lambda(on_next = (d) -> println(d))
next!(actor, 1)

# output
1

```

See also: [`LambdaActor`](@ref), [`AbstractActor`](@ref)
"""
lambda(; on_next::N = nothing, on_error::E = nothing, on_complete::C = nothing) where { N, E, C } = LambdaActor{N, E, C}(on_next, on_error, on_complete)
