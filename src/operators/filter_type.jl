export filter_type

import Base: show

"""
    filter_type(type::Type{ T }) where { T }

Creates a `filter_type` operator, which filters items of the source Observable by emitting only
those that match a specified `T` type with a `<:` operator. This operator is a more efficient version of
`filter(v -> v <: T) |> map(T, v -> v)` operators chain.

# Producing

Stream of type `<: Subscribable{ T }` where `T` refers to `type` argument

# Examples
```jldoctest
using Rocket

source = from(Real[ 1, 2.0, 3, 4.0, 5, 6.0 ])
subscribe!(source |> filter_type(Int), logger())
;

# output

[LogActor] Data: 1
[LogActor] Data: 3
[LogActor] Data: 5
[LogActor] Completed
```

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
filter_type(::Type{ T }) where { T }  = FilterTypeOperator{T}()

struct FilterTypeOperator{T} <: InferableOperator end

on_call!(::Type{T}, ::Type{T}, operator::FilterTypeOperator{T}, source) where { T    }      = source
on_call!(::Type{L}, ::Type{T}, operator::FilterTypeOperator{T}, source) where { L, T <: L } = proxy(T, source, FilterTypeProxy{L, T}())
on_call!(::Type{L}, ::Type{T}, operator::FilterTypeOperator{T}, source) where { L, T }      = error("filter_type(T) operator usage error. Cannot filter $(T) elements from stream of $(L) elements.")

operator_right(::FilterTypeOperator{T}, ::Type{T}) where { T }         = T
operator_right(::FilterTypeOperator{T}, ::Type{L}) where { L, T <: L } = T
operator_right(::FilterTypeOperator{T}, ::Type{L}) where { L, T }      = error("filter_type(T) operator creation error. Cannot filter $(T) elements from stream of $(L) elements.")

struct FilterTypeProxy{L, T} <: ActorProxy end

actor_proxy!(::Type{T}, proxy::FilterTypeProxy{L, T}, actor::A) where { L, A, T } = FilterTypeActor{L, A, T}(actor)

struct FilterTypeActor{L, A, T} <: Actor{L}
    actor :: A
end

on_next!(actor::FilterTypeActor{L, A, T}, data::T) where { L, A, T } = next!(actor.actor, data)
on_next!(::FilterTypeActor, data)                                    = nothing

on_error!(actor::FilterTypeActor, err) = error!(actor.actor, err)
on_complete!(actor::FilterTypeActor)   = complete!(actor.actor)

Base.show(io::IO, ::FilterTypeOperator)         = print(io, "FilterTypeOperator()")
Base.show(io::IO, ::FilterTypeProxy)            = print(io, "FilterTypeProxy()")
Base.show(io::IO, ::FilterTypeActor{L}) where L = print(io, "FilterTypeActor($L)")
