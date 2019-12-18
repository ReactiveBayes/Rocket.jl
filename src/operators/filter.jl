export filter
export FilterOperator, on_call!, operator_right
export FilterProxy, actor_proxy!
export FilterActor, on_next!, on_error!, on_complete!
export @CreateFilterOperator

import Base: filter

"""
    filter(filterFn::Function)

Creates a filter operator, which filters items by the source Observable by emitting only
those that satisfy a specified `filterFn` predicate.

# Arguments
- `filterFn::Function`: predicate function with `(data::T) -> Bool` signature

# Examples
```jldoctest
using Rx

source = from([ 1, 2, 3 ])
subscribe!(source |> filter((d) -> d % 2 == 0), LoggerActor{Int}())
;

# output

[LogActor] Data: 2
[LogActor] Completed

```

See also: [`Operator`](@ref), ['ProxyObservable'](@ref)
"""
filter(filterFn::Function) = FilterOperator(filterFn)

struct FilterOperator <: InferrableOperator
    filterFn::Function
end

function on_call!(::Type{L}, ::Type{L}, operator::FilterOperator, source::S) where { S <: Subscribable{L} } where L
    return ProxyObservable{L}(source, FilterProxy{L}(operator.filterFn))
end

operator_right(operator::FilterOperator, ::Type{L}) where L = L

struct FilterProxy{L} <: ActorProxy
    filterFn::Function
end

actor_proxy!(proxy::FilterProxy{L}, actor::A) where { A <: AbstractActor{L} } where L = FilterActor{L, A}(proxy.filterFn, actor)


struct FilterActor{L, A <: AbstractActor{L} } <: Actor{L}
    filterFn :: Function
    actor    :: A
end

function on_next!(f::FilterActor{L, A}, data::L) where { A <: AbstractActor{L} } where L
    if (Base.invokelatest(f.filterFn, data))
        next!(f.actor, data)
    end
end

on_error!(f::FilterActor, err) = error!(f.actor, err)
on_complete!(f::FilterActor)   = complete!(f.actor)


"""
    @CreateFilterOperator(name, T, filterFn)

Creates a custom filter operator, which can be used as `nameFilterOperator()`.

# Arguments
- `name`: custom operator name
- `T`: type of data of input source
- `filterFn`: predicate function, assumed to be pure

# Generates
- `nameFilterOperator()` function

# Examples
```jldoctest
using Rx

@CreateFilterOperator(EvenInt, Int, (d) -> d % 2 == 0)

source = from([ 1, 2, 3 ])
subscribe!(source |> EvenIntFilterOperator(), LoggerActor{Int}())
;

# output

[LogActor] Data: 2
[LogActor] Completed

```

"""
macro CreateFilterOperator(name, T, filterFn)
    operatorName = Symbol(name, "FilterOperator")
    proxyName    = Symbol(name, "FilterProxy")
    actorName    = Symbol(name, "FilterActor")

    operatorDefinition = quote
        struct $operatorName <: Rx.TypedOperator{$T, $T} end

        function Rx.on_call!(::Type{$T}, ::Type{$T}, operator::($operatorName), source::S) where { S <: Rx.Subscribable{$T} }
            return Rx.ProxyObservable{$T}(source, ($proxyName)())
        end
    end

    proxyDefinition = quote
        struct $proxyName <: Rx.ActorProxy end

        Rx.actor_proxy!(proxy::($proxyName), actor::A) where { A <: Rx.AbstractActor{$T} } = ($actorName){A}(actor)
    end

    actorDefintion = quote
        struct $actorName{ A <: Rx.AbstractActor{$T} } <: Rx.Actor{$T}
            actor::A
        end

        Rx.on_next!(a::($actorName){A}, data::$T) where A <: Rx.AbstractActor{$T} = begin
            __inlined_lambda = $filterFn
            if (__inlined_lambda(data))
                Rx.next!(a.actor, data)
            end
        end

        Rx.on_error!(a::($actorName), err) = Rx.error!(a.actor, err)
        Rx.on_complete!(a::($actorName))   = Rx.complete!(a.actor)
    end

    generated = quote
        $operatorDefinition
        $proxyDefinition
        $actorDefintion
    end

    return esc(generated)
end
