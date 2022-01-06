export filter_type

import Base: show

"""
    filter_type(type::Type{R}) where R

Creates a `filter_type` operator, which filters items of the source Observable by emitting only
those that match a specified `R` type with a `<:` operator. This operator is a more efficient version of
`filter(v -> v <: R) |> map(OpType(R), v -> v)` operators chain.

# Producing

Stream of type `<: Subscribable{R}` where `R` refers to the `type` argument

# Examples
```jldoctest
using Rocket

source = from_iterable(Real[ 1, 2.0, 3, 4.0, 5, 6.0 ])
subscribe!(source |> filter_type(Int), logger())
;

# output

[LogActor] Data: 1
[LogActor] Data: 3
[LogActor] Data: 5
[LogActor] Completed
```

See also: [`Operator`](@ref), [`from_iterable`](@ref), [`logger`](@ref)
"""
filter_type(::Type{R}) where R  = FilterTypeOperator{R}()

struct FilterTypeOperator{R} <: Operator end

on_call!(::Type{R}, ::Type{R}, operator::FilterTypeOperator{R}, source)    where { R    }         = source
on_call!(::Type{L}, ::Type{R}, operator::FilterTypeOperator{R}, source::S) where { L, R <: L, S } = FilterTypeSubscribable{R, S}(source)
on_call!(::Type{L}, ::Type{R}, operator::FilterTypeOperator{R}, source)    where { L, R }         = error("filter_type(T) operator usage error. Cannot filter $(R) elements from stream of $(L) elements.")

operator_eltype(::FilterTypeOperator{R}, ::Type{R}) where { R }         = R
operator_eltype(::FilterTypeOperator{R}, ::Type{L}) where { L, R <: L } = R
operator_eltype(::FilterTypeOperator{R}, ::Type{L}) where { L, R }      = error("filter_type(T) operator creation error. Cannot filter $(R) elements from stream of $(L) elements.")

struct FilterTypeSubscribable{R, S} <: Subscribable{R} 
    source :: S
end

function on_subscribe!(subscribable::FilterTypeSubscribable{R}, actor::A) where { R, A }
    return subscribe!(subscribable.source, FilterTypeActor{R, A}(actor))
end

struct FilterTypeActor{R, A}
    actor :: A
end

on_next!(actor::FilterTypeActor{R, A}, data::R) where { R, A } = next!(actor.actor, data)
on_next!(::FilterTypeActor, data)                              = begin end

on_error!(actor::FilterTypeActor, err) = error!(actor.actor, err)
on_complete!(actor::FilterTypeActor)   = complete!(actor.actor)

Base.show(io::IO, ::FilterTypeOperator)                = print(io, "FilterTypeOperator()")
Base.show(io::IO, ::FilterTypeSubscribable{R}) where R = print(io, "FilterTypeSubscribable($R)")
Base.show(io::IO, ::FilterTypeActor{R}) where R        = print(io, "FilterTypeActor($R)")
