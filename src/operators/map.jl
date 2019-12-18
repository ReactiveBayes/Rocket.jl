export map
export MapOperator, on_call!
export MapProxy, actor_proxy!
export MapActor, on_next!, on_error!, on_complete!
export @CreateMapOperator

import Base: map

"""
    map(::Type{R}, mappingFn::Function) where R

Creates a map operator, which applies a given `mappingFn` to each value emmited by the source
Observable, and emits the resulting values as an Observable. You have to specify output R type after
`mappingFn` projection.

# Arguments
- `::Type{R}`: the type of data of transformed value, may be or may not be the same as source type
- `mappingFn::Function`: transformation function with `(data::L) -> R` signature, where L is type of data in input source

# Examples
```jldoctest
using Rx

source = from([ 1, 2, 3 ])
subscribe!(source |> map(Int, (d) -> d ^ 2), LoggerActor{Int}())
;

# output

[LogActor] Data: 1
[LogActor] Data: 4
[LogActor] Data: 9
[LogActor] Completed

```

See also: [`Operator`](@ref), ['ProxyObservable'](@ref)
"""
map(::Type{R}, mappingFn::Function) where R = MapOperator{R}(mappingFn)

struct MapOperator{R} <: RightTypedOperator{R}
    mappingFn::Function
end

function on_call!(::Type{L}, ::Type{R}, operator::MapOperator{R}, source::S) where { S <: Subscribable{L} } where L where R
    return ProxyObservable{R}(source, MapProxy{L, R}(operator.mappingFn))
end

struct MapProxy{L, R} <: ActorProxy
    mappingFn::Function
end

actor_proxy!(proxy::MapProxy{L, R}, actor::A) where { A <: AbstractActor{R} } where L where R = MapActor{L, R, A}(proxy.mappingFn, actor)

struct MapActor{L, R, A <: AbstractActor{R} } <: Actor{L}
    mappingFn  :: Function
    actor      :: A
end

on_next!(m::MapActor{L, R, A},  data::L) where { A <: AbstractActor{R} } where L where R = next!(m.actor, Base.invokelatest(m.mappingFn, data))
on_error!(m::MapActor, err)                                                              = error!(m.actor, err)
on_complete!(m::MapActor)                                                                = complete!(m.actor)

"""
    @CreateMapOperator(name, L, R, mappingFn)

Creates a custom map operator, which can be used as `nameMapOperator()`.

# Arguments
- `name`: custom operator name
- `L`: type of input data
- `R`: type of output data after `mappingFn` projection
- `mappingFn`: transformation function, assumed to be pure

# Generates
- `nameMapOperator()` function

# Examples
```jldoctest
using Rx

@CreateMapOperator(SquaredInt, Int, Int, (d) -> d ^ 2)

source = from([ 1, 2, 3 ])
subscribe!(source |> SquaredIntMapOperator(), LoggerActor{Int}())
;

# output

[LogActor] Data: 1
[LogActor] Data: 4
[LogActor] Data: 9
[LogActor] Completed

```

"""
macro CreateMapOperator(name, L, R, mappingFn)
    operatorName   = Symbol(name, "MapOperator")
    proxyName      = Symbol(name, "MapProxy")
    actorName      = Symbol(name, "MapActor")

    operatorDefinition = quote
        struct $operatorName <: Rx.TypedOperator{$L, $R} end

        function Rx.on_call!(::Type{$L}, ::Type{$R}, operator::($operatorName), source::S) where { S <: Rx.Subscribable{$L} }
            return Rx.ProxyObservable{$R}(source, ($proxyName)())
        end
    end

    proxyDefinition = quote
        struct $proxyName <: Rx.ActorProxy end

        Rx.actor_proxy!(proxy::($proxyName), actor::A) where { A <: Rx.AbstractActor{$R} } = ($actorName){A}(actor)
    end

    actorDefinition = quote
        struct $actorName{ A <: Rx.AbstractActor{$R} } <: Rx.Actor{$L}
            actor::A
        end

        Rx.on_next!(a::($actorName){A}, data::($L)) where { A <: Rx.AbstractActor{$R} }  = begin
            __inlined_lambda = $mappingFn
            Rx.next!(a.actor, __inlined_lambda(data))
        end

        Rx.on_error!(a::($actorName), err) = Rx.error!(a.actor, err)
        Rx.on_complete!(a::($actorName))   = Rx.complete!(a.actor)
    end

    generated = quote
        $operatorDefinition
        $proxyDefinition
        $actorDefinition
    end

    return esc(generated)
end
