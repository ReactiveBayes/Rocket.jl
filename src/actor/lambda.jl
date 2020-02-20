export LambdaActor, lambda

"""
    LambdaActor{D, N, E, C}(on_next::N, on_error::E, on_complete::C) where D

    Lambda actor wraps `on_next`, `on_error`, `on_complete` callbacks for data, error and complete events.
    Should not be used explicitly, use [`lambda`](@ref) creation operator instead.

    # Constructor arguments
    - `on_next`: Callback for data event. Optional. Default is `nothing`.
    - `on_error`: Callback for error event. Optional. Default is `nothing`.
    - `on_complete`: Callback for complete event. Optional. Default is `nothing`.

    See also: [`Actor`](@ref), [`lambda`](@ref)
"""
struct LambdaActor{D, NextCallback, ErrorCallback, CompleteCallback} <: Actor{D}
    on_next     :: NextCallback
    on_error    :: ErrorCallback
    on_complete :: CompleteCallback
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

struct LambdaActorFactory{NextCallback, ErrorCallback, CompleteCallback} <: AbstractActorFactory
    on_next     :: NextCallback
    on_error    :: ErrorCallback
    on_complete :: CompleteCallback
end

function create_actor(::Type{L}, factory::LambdaActorFactory{N, E, C}) where { L, N, E, C }
    return LambdaActor{L, N, E, C}(factory.on_next, factory.on_error, factory.on_complete)
end

"""
    lambda(; on_next = nothing, on_error = nothing, on_complete = nothing)
    lambda(::Type{T}; on_next = nothing, on_error = nothing, on_complete = nothing) where T

    Creation operator for the 'LambdaActor' actor.

    # Examples

    ```jldoctest
    using Rocket

    actor = lambda(Int; on_next = (d) -> println(d))
    actor isa LambdaActor{Int}

    # output
    true
    ```

    See also: [`LambdaActor`](@ref), [`AbstractActor`](@ref)
"""
lambda(; on_next::N = nothing, on_error::E = nothing, on_complete::C = nothing)          where { N <: Union{Nothing, Function}, E <: Union{Nothing, Function}, C <: Union{Nothing, Function} }    = LambdaActorFactory{N, E, C}(on_next, on_error, on_complete)
lambda(::Type{T}; on_next::N = nothing, on_error::E = nothing, on_complete::C = nothing) where { T, N <: Union{Nothing, Function}, E <: Union{Nothing, Function}, C <: Union{Nothing, Function} } = LambdaActor{T, N, E, C}(on_next, on_error, on_complete)
