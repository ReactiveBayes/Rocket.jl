export filter

import Base: filter
import Base: show

"""
    filter(filterFn::F) where { F <: Function }

Creates a filter operator, which filters items by the source Observable by emitting only
those that satisfy a specified `filterFn` predicate.

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream

# Arguments
- `filterFn::F`: predicate function with `(data::T) -> Bool` signature

# Examples
```jldoctest
using Rocket

source = from([ 1, 2, 3, 4, 5, 6 ])
subscribe!(source |> filter((d) -> d % 2 == 0), logger())
;

# output

[LogActor] Data: 2
[LogActor] Data: 4
[LogActor] Data: 6
[LogActor] Completed
```

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
filter(filterFn::F) where { F <: Function }  = FilterOperator{F}(filterFn)

struct FilterOperator{F} <: InferableOperator
    filterFn::F
end

function on_call!(::Type{L}, ::Type{L}, operator::FilterOperator{F}, source) where { L, F }
    return proxy(L, source, FilterProxy{L, F}(operator.filterFn))
end

operator_right(operator::FilterOperator, ::Type{L}) where L = L

struct FilterProxy{L, F} <: ActorProxy
    filterFn::F
end

actor_proxy!(proxy::FilterProxy{L, F}, actor::A) where { L, A, F } = FilterActor{L, A, F}(proxy.filterFn, actor)

struct FilterActor{L, A, F} <: Actor{L}
    filterFn :: F
    actor    :: A
end

is_exhausted(actor::FilterActor) = is_exhausted(actor.actor)

function on_next!(f::FilterActor{L}, data::L) where L
    if f.filterFn(data)
        next!(f.actor, data)
    end
end

on_error!(f::FilterActor, err) = error!(f.actor, err)
on_complete!(f::FilterActor)   = complete!(f.actor)

Base.show(io::IO, ::FilterOperator)         = print(io, "FilterOperator()")
Base.show(io::IO, ::FilterProxy{L}) where L = print(io, "FilterProxy($L)")
Base.show(io::IO, ::FilterActor{L}) where L = print(io, "FilterActor($L)")
