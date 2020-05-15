export some

import Base: show

"""
    some()

Creates a some operator, which filters out `nothing` items by the source Observable by emitting only
those that not equal to `nothing`.

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream `<: Subscribable{Union{L, Nothing}}`

# Examples
```jldoctest
using Rocket

source = from([ 1, nothing, 3 ])
subscribe!(source |> some(), logger())
;

# output

[LogActor] Data: 1
[LogActor] Data: 3
[LogActor] Completed

```

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref), [`max`](@ref), [`min`](@ref), [`logger`](@ref)
"""
some() = SomeOperator()

struct SomeOperator <: InferableOperator end

function on_call!(::Type{Union{L, Nothing}}, ::Type{L}, ::SomeOperator, source) where L
    return proxy(L, source, SomeProxy())
end

operator_right(::SomeOperator, ::Type{Union{L, Nothing}}) where L = L
operator_right(::SomeOperator, ::Type{L})                 where L = error("some() operator can operate on streams with data type '<: Union{Nothing, $L}', but '<: $L' was found.")

struct SomeProxy <: ActorProxy end

actor_proxy!(::Type{L}, proxy::SomeProxy, actor::A) where { L, A } = SomeActor{L, A}(actor)

struct SomeActor{L, A} <: Actor{Union{L, Nothing}}
    actor :: A
end

function on_next!(actor::SomeActor{L}, data::Union{L, Nothing}) where L
    if data !== nothing
        next!(actor.actor, data)
    end
end

on_error!(actor::SomeActor, err) = error!(actor.actor, err)
on_complete!(actor::SomeActor)   = complete!(actor.actor)

Base.show(io::IO, ::SomeOperator)         = print(io, "SomeOperator()")
Base.show(io::IO, ::SomeProxy)            = print(io, "SomeProxy()")
Base.show(io::IO, ::SomeActor{L}) where L = print(io, "SomeActor($L)")
