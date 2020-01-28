export filter
export FilterOperator, on_call!, operator_right
export FilterProxy, actor_proxy!
export FilterActor, on_next!, on_error!, on_complete!, is_exhausted
export @CreateFilterOperator

import Base: filter
import Base: show

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
subscribe!(source |> filter((d) -> d % 2 == 0), logger())
;

# output

[LogActor] Data: 2
[LogActor] Completed

```

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
filter(filterFn::Function) = FilterOperator(filterFn)

struct FilterOperator <: InferableOperator
    filterFn::Function
end

function on_call!(::Type{L}, ::Type{L}, operator::FilterOperator, source) where L
    return proxy(L, source, FilterProxy{L}(operator.filterFn))
end

operator_right(operator::FilterOperator, ::Type{L}) where L = L

struct FilterProxy{L} <: ActorProxy
    filterFn::Function
end

actor_proxy!(proxy::FilterProxy{L}, actor::A) where L where A = FilterActor{L, A}(proxy.filterFn, actor)

struct FilterActor{L, A} <: Actor{L}
    filterFn :: Function
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

Base.show(io::IO, operator::FilterOperator)         = print(io, "FilterOperator()")
Base.show(io::IO, proxy::FilterProxy{L})    where L = print(io, "FilterProxy($L)")
Base.show(io::IO, actor::FilterActor{L})    where L = print(io, "FilterActor($L)")


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
subscribe!(source |> EvenIntFilterOperator(), logger())
;

# output

[LogActor] Data: 2
[LogActor] Completed

```

See also: [`AbstractOperator`](@ref), [`TypedOperator`](@ref), [`ProxyObservable`](@ref), [`filter`](@ref), [`logger`](@ref)
"""
macro CreateFilterOperator(name, L, filterFn)
    operatorName = Symbol(name, "FilterOperator")
    proxyName    = Symbol(name, "FilterProxy")
    actorName    = Symbol(name, "FilterActor")

    operatorDefinition = quote
        struct $operatorName <: Rx.TypedOperator{$L, $L} end

        function Rx.on_call!(::Type{$L}, ::Type{$L}, operator::($operatorName), source)
            return Rx.proxy($L, source, ($proxyName)())
        end

        Base.show(io::IO, operator::($operatorName)) = print(io, string($operatorName), "()")
    end

    proxyDefinition = quote
        struct $proxyName <: Rx.ActorProxy end

        Rx.actor_proxy!(proxy::($proxyName), actor::A) where A = ($actorName){A}(actor)

        Base.show(io::IO, proxy::($proxyName)) = print(io, string($proxyName), "(", string($L), ")")
    end

    actorDefintion = quote
        struct $actorName{A} <: Rx.Actor{$L}
            actor :: A
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

        Base.show(io::IO, actor::($actorName)) = print(io, string($actorName), "(", string($L), ")")
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
            return Rx.proxy(L, source, ($proxyName){L}())
        end

        Rx.operator_right(operator::($operatorName){L}, ::Type{L}) where L = L

        Base.show(io::IO, operator::($operatorName){L}) where L = print(io, string($operatorName), "(", L, ")")
    end

    proxyDefinition = quote
        struct $proxyName{L} <: Rx.ActorProxy end

        Rx.actor_proxy!(proxy::($proxyName){L}, actor::A) where L where A = ($actorName){L, A}(actor)

        Base.show(io::IO, proxy::($proxyName){L}) where L = print(io, string($proxyName), "(", L, ")")
    end

    actorDefintion = quote
        struct $actorName{L, A} <: Rx.Actor{L}
            actor :: A
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

        Base.show(io::IO, actor::($actorName){L}) where L = print(io, string($actorName), "(", L, ")")
    end

    generated = quote
        $operatorDefinition
        $proxyDefinition
        $actorDefintion
    end

    return esc(generated)
end
