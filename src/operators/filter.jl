export filter

import Base: filter
import Base: show

"""
    filter(filterFn::F)

Creates a filter operator, which filters items of the source Observable by emitting only
those that satisfy a specified `filterFn` predicate.

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream

# Arguments
- `filterFn::F`: predicate function with `(data) -> Bool` signature

# Examples
```jldoctest
using Rocket

source = from_iterable([ 1, 2, 3, 4, 5, 6 ])
subscribe!(source |> filter((d) -> d % 2 == 0), logger())
;

# output

[LogActor] Data: 2
[LogActor] Data: 4
[LogActor] Data: 6
[LogActor] Completed
```

See also: [`Operator`](@ref), [`from_iterable`](@ref), [`logger`](@ref)
"""
filter(filter::F) where { F <: Function }  = FilterOperator{F}(filter)

struct FilterOperator{F} <: Operator
    filter :: F
end

operator_eltype(::FilterOperator, ::Type{L}) where L = L

struct FilterSubscribable{L, F, S} <: Subscribable{L}
    filter :: F
    source :: S
end

struct FilterActor{F, A}
    filter :: F
    actor  :: A
end

function on_call!(::Type{L}, ::Type{L}, operator::FilterOperator{F}, source::S) where { L, F, S }
    return FilterSubscribable{L, F, S}(operator.filter, source)
end

function on_subscribe!(source::FilterSubscribable{L, F}, actor::A) where { L, F, A }
    return subscribe!(source.source, FilterActor{F, A}(source.filter, actor))
end

function on_next!(actor::FilterActor, data)
    if actor.filter(data)
        next!(actor.actor, data)
    end
end

on_error!(actor::FilterActor, err) = error!(actor.actor, err)
on_complete!(actor::FilterActor)   = complete!(actor.actor)

Base.show(io::IO, ::FilterOperator)                = print(io, "FilterOperator()")
Base.show(io::IO, ::FilterSubscribable{L}) where L = print(io, "FilterSubscribable($L)")
Base.show(io::IO, ::FilterActor{L}) where L        = print(io, "FilterActor($L)")
