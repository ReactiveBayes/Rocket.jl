export filter
export FilterOperator, on_call!
export FilterProxy, actor_proxy!
export FilterActor, on_next!, on_error!, on_complete!
export @CreateFilterOperator

import Base: filter

"""
    filter(::Type{T}, filterFn::Function) where T

Creates a filter operator, which filters items by the source Observable by emitting only
those that satisfy a specified `filterFn` predicate.

# Arguments
- `::Type{T}`: the type of data of source
- `filterFn::Function`: predicate function with `(data::T) -> Bool` signature

# Examples
```jldoctest
using Rx

source = from([ 1, 2, 3 ])
subscribe!(source |> filter(Int, (d) -> d % 2 == 0), LoggerActor{Int}())
;

# output

[LogActor] Data: 2
[LogActor] Completed

```

See also: [`Operator`](@ref), ['ProxyObservable'](@ref)
"""
filter(::Type{T}, filterFn::Function) where T = FilterOperator{T}(filterFn)

struct FilterOperator{T} <: Operator{T, T}
    filterFn::Function
end

function on_call!(operator::FilterOperator{T}, source::S) where { S <: Subscribable{T} } where T
    return ProxyObservable{T}(source, FilterProxy{T}(operator.filterFn))
end

struct FilterProxy{T} <: ActorProxy
    filterFn::Function
end

actor_proxy!(proxy::FilterProxy{T}, actor::A) where { A <: AbstractActor{T} } where T = FilterActor{T, A}(proxy.filterFn, actor)


struct FilterActor{T, A <: AbstractActor{T} } <: Actor{T}
    filterFn :: Function
    actor    :: A
end

function on_next!(f::FilterActor{T, A}, data::T) where { A <: AbstractActor{T} } where T
    if (Base.invokelatest(f.filterFn, data))
        next!(f.actor, data)
    end
end

on_error!(f::FilterActor, error) = error!(f.actor, error)
on_complete!(f::FilterActor)     = complete!(f.actor)


"""
    @CreateFilterOperator(name, filterFn)

Creates a custom filter operator, which can be used as `nameFilterOperator{T}()`.

# Arguments
- `name`: custom operator name
- `filterFn`: predicate function, assumed to be pure

# Generates
- `nameFilterOperator{T}()` function

# Examples
```jldoctest
using Rx

@CreateFilterOperator(Even, (d) -> d % 2 == 0)

source = from([ 1, 2, 3 ])
subscribe!(source |> EvenFilterOperator{Int}(), LoggerActor{Int}())
;

# output

[LogActor] Data: 2
[LogActor] Completed

```

"""
macro CreateFilterOperator(name, filterFn)
    operatorName = Symbol(name, "FilterOperator")
    proxyName    = Symbol(name, "FilterProxy")
    actorName    = Symbol(name, "FilterActor")

    operatorDefinition = quote
        struct $operatorName{T} <: Rx.Operator{T, T} end

        function Rx.on_call!(operator::($operatorName){T}, source::S) where { S <: Rx.Subscribable{T} } where T
            return Rx.ProxyObservable{T}(source, ($proxyName){T}())
        end
    end

    proxyDefinition = quote
        struct $proxyName{T} <: Rx.ActorProxy end

        Rx.actor_proxy!(proxy::($proxyName){T}, actor::A) where { A <: Rx.AbstractActor{T} } where T = ($actorName){T, A}(actor)
    end

    actorDefintion = quote
        struct $actorName{T, A <: Rx.AbstractActor{T} } <: Rx.Actor{T}
            actor::A
        end

        Rx.on_next!(a::($actorName){T, A}, data::T) where A <: Rx.AbstractActor{T} where T = begin
            __inlined_lambda = $filterFn
            if (__inlined_lambda(data))
                Rx.next!(a.actor, data)
            end
        end

        Rx.on_error!(a::($actorName), error) = Rx.error!(a.actor, error)
        Rx.on_complete!(a::($actorName))     = Rx.complete!(a.actor)
    end

    generated = quote
        $operatorDefinition
        $proxyDefinition
        $actorDefintion
    end

    return esc(generated)
end
