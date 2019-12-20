export some
export SomeOperator, on_call!, operator_right
export SomeProxy, actor_proxy!
export SomeActor, on_next!, on_error!, on_complete!

"""
    some()

Creates a some operator, which filters out `nothing` items by the source Observable by emitting only
those that not equal to `nothing`.

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream `<: Subscribable{Union{L, Nothing}}`

# Examples
```jldoctest
using Rx

source = Rx.from([ 1, nothing, 3 ])
subscribe!(source |> some(), LoggerActor{Int}())
;

# output

[LogActor] Data: 1
[LogActor] Data: 3
[LogActor] Completed

```

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref), [`max`](@ref), [`min`](@ref)
"""
some() = SomeOperator()

struct SomeOperator <: InferableOperator end

function on_call!(::Type{Union{L, Nothing}}, ::Type{L}, operator::SomeOperator, source) where L
    return ProxyObservable{L}(source, SomeProxy{L}())
end

operator_right(operator::SomeOperator, ::Type{Union{L, Nothing}}) where L = L

struct SomeProxy{L} <: ActorProxy end

actor_proxy!(proxy::SomeProxy{L}, actor::A) where { A <: AbstractActor{L} } where L = SomeActor{L, A}(actor)

struct SomeActor{ L, A <: AbstractActor{L} } <: Actor{ Union{L, Nothing} }
    actor :: A
end

function on_next!(f::SomeActor{L, A}, data::Union{L, Nothing}) where { A <: AbstractActor{L} } where L
    if data != nothing
        next!(f.actor, data)
    end
end

on_error!(f::SomeActor{L, A}, err) where { A <: AbstractActor{L} } where L = error!(f.actor, err)
on_complete!(f::SomeActor{L, A})   where { A <: AbstractActor{L} } where L = complete!(f.actor)
