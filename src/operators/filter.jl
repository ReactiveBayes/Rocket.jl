export filter

import Base: filter
import Base: show

"""
    filter(filterFn::F) where { F <: Function }

Creates a filter operator, which filters items of the source Observable by emitting only
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
    return proxy(L, source, FilterProxy{F}(operator.filterFn))
end

operator_right(operator::FilterOperator, ::Type{L}) where L = L

struct FilterProxy{F} <: ActorProxy
    filterFn::F
end

actor_proxy!(::Type{L}, proxy::FilterProxy{F}, actor::A) where { L, A, F } = FilterActor{L, A, F}(proxy.filterFn, actor)

struct FilterActor{L, A, F} <: Actor{L}
    filterFn :: F
    actor    :: A
end

function on_next!(actor::FilterActor{L}, data::L) where L
    if actor.filterFn(data)
        next!(actor.actor, data)
    end
end

on_error!(actor::FilterActor, err) = error!(actor.actor, err)
on_complete!(actor::FilterActor)   = complete!(actor.actor)

Base.show(io::IO, ::FilterOperator)         = print(io, "FilterOperator()")
Base.show(io::IO, ::FilterProxy)            = print(io, "FilterProxy()")
Base.show(io::IO, ::FilterActor{L}) where L = print(io, "FilterActor($L)")
