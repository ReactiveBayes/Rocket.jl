export filter
export FilterOperator, on_call!, operator_right
export FilterProxy, actor_proxy!
export FilterActor, on_next!, on_error!, on_complete!, is_exhausted
export @CreateFilterOperator

import Base: filter

"""
    filter(filterFn::Function)

Creates a filter operator, which filters items by the source Observable by emitting only
those that satisfy a specified `filterFn` predicate.

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream

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

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref)
"""
filter(filterFn::Function) = FilterOperator(filterFn)

struct FilterOperator <: InferableOperator
    filterFn::Function
end

function on_call!(::Type{L}, ::Type{L}, operator::FilterOperator, source) where L
    return ProxyObservable{L}(source, FilterProxy{L}(operator.filterFn))
end

operator_right(operator::FilterOperator, ::Type{L}) where L = L

struct FilterProxy{L} <: ActorProxy
    filterFn::Function
end

actor_proxy!(proxy::FilterProxy{L}, actor) where L = FilterActor{L}(proxy.filterFn, actor)

struct FilterActor{L} <: Actor{L}
    filterFn :: Function
    actor
end

is_exhausted(actor::FilterActor) = is_exhausted(actor.actor)

function on_next!(f::FilterActor{L}, data::L) where L
    if (Base.invokelatest(f.filterFn, data))
        next!(f.actor, data)
    end
end

on_error!(f::FilterActor, err) = error!(f.actor, err)
on_complete!(f::FilterActor)   = complete!(f.actor)


"""
    @CreateFilterOperator(name, L, filterFn)

Creates a custom filter operator, which can be used as `nameFilterOperator()`.

# Arguments
- `name`: custom operator name
- `L`: type of data of input source
- `filterFn`: predicate function, assumed to be pure

# Generates
- `nameFilterOperator()` function

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream

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

See also: [`AbstractOperator`](@ref), [`TypedOperator`](@ref), [`ProxyObservable`](@ref), [`filter`](@ref)
"""
macro CreateFilterOperator(name, L, filterFn)
    operatorName = Symbol(name, "FilterOperator")
    proxyName    = Symbol(name, "FilterProxy")
    actorName    = Symbol(name, "FilterActor")

    operatorDefinition = quote
        struct $operatorName <: Rx.TypedOperator{$L, $L} end

        function Rx.on_call!(::Type{$L}, ::Type{$L}, operator::($operatorName), source)
            return Rx.ProxyObservable{$L}(source, ($proxyName)())
        end

        function Rx.on_call!(::Type{$L}, ::Type{$L}, operator::($operatorName), source::SingleObservable{$L})
            __inlined_lambda = $filterFn
            if __inlined_lambda(source.value)
                return of(source.value)
            else
                return completed($L)
            end
        end
    end

    proxyDefinition = quote
        struct $proxyName <: Rx.ActorProxy end

        Rx.actor_proxy!(proxy::($proxyName), actor) = ($actorName)(actor)
    end

    actorDefintion = quote
        struct $actorName <: Rx.Actor{$L}
            actor
        end

        Rx.is_exhausted(a::($actorName)) = is_exhausted(a.actor)

        Rx.on_next!(a::($actorName), data::($L)) = begin
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

macro CreateFilterOperator(name, filterFn)
    operatorName = Symbol(name, "FilterOperator")
    proxyName    = Symbol(name, "FilterProxy")
    actorName    = Symbol(name, "FilterActor")

    operatorDefinition = quote
        struct $operatorName{L} <: Rx.LeftTypedOperator{L} end

        function Rx.on_call!(::Type{L}, ::Type{L}, operator::($operatorName){L}, source) where L
            return Rx.ProxyObservable{L}(source, ($proxyName){L}())
        end

        function Rx.on_call!(::Type{L}, ::Type{L}, operator::($operatorName){L}, source::SingleObservable{L}) where L
            __inlined_lambda = $filterFn
            if __inlined_lambda(source.value)
                return of(source.value)
            else
                return completed(L)
            end
        end

        operator_right(operator::($operatorName){L}, ::Type{L}) where L = L
    end

    proxyDefinition = quote
        struct $proxyName{L} <: Rx.ActorProxy end

        Rx.actor_proxy!(proxy::($proxyName){L}, actor) where L = ($actorName){L}(actor)
    end

    actorDefintion = quote
        struct $actorName{L} <: Rx.Actor{L}
            actor
        end

        Rx.is_exhausted(a::($actorName)) = is_exhausted(a.actor)

        Rx.on_next!(a::($actorName){L}, data::L) where L = begin
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
