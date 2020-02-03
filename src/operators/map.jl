export map
export @CreateMapOperator

import Base: map
import Base: show

"""
    map(::Type{R}, mappingFn::Function) where R

Creates a map operator, which applies a given `mappingFn` to each value emmited by the source
Observable, and emits the resulting values as an Observable. You have to specify output R type after
`mappingFn` projection.

# Arguments
- `::Type{R}`: the type of data of transformed value, may be or may not be the same as source type
- `mappingFn::Function`: transformation function with `(data::L) -> R` signature, where L is type of data in input source

# Producing

Stream of type `<: Subscribable{R}`

# Examples
```jldoctest
using Rocket

source = from([ 1, 2, 3 ])
subscribe!(source |> map(Int, (d) -> d ^ 2), logger())
;

# output

[LogActor] Data: 1
[LogActor] Data: 4
[LogActor] Data: 9
[LogActor] Completed

```

See also: [`AbstractOperator`](@ref), [`RightTypedOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
map(::Type{R}, mappingFn::Function) where R = MapOperator{R}(mappingFn)

struct MapOperator{R} <: RightTypedOperator{R}
    mappingFn::Function
end

function on_call!(::Type{L}, ::Type{R}, operator::MapOperator{R}, source) where L where R
    return proxy(R, source, MapProxy{L}(operator.mappingFn))
end

struct MapProxy{L} <: ActorProxy
    mappingFn::Function
end

actor_proxy!(proxy::MapProxy{L}, actor::A) where L where A = MapActor{L, A}(proxy.mappingFn, actor)

struct MapActor{L, A} <: Actor{L}
    mappingFn  :: Function
    actor      :: A
end

is_exhausted(actor::MapActor) = is_exhausted(actor.actor)

on_next!(m::MapActor{L},  data::L) where L = next!(m.actor, m.mappingFn(data))
on_error!(m::MapActor, err)                = error!(m.actor, err)
on_complete!(m::MapActor)                  = complete!(m.actor)

Base.show(io::IO, operator::MapOperator{R}) where R   = print(io, "MapOperator( -> $R)")
Base.show(io::IO, proxy::MapProxy{L})       where L   = print(io, "MapProxy($L)")
Base.show(io::IO, actor::MapActor{L})       where L   = print(io, "MapActor($L)")

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

# Producing

Stream of type `<: Subscribable{R}`

# Examples
```jldoctest
using Rocket

@CreateMapOperator(SquaredInt, Int, Int, (d) -> d ^ 2)

source = from([ 1, 2, 3 ])
subscribe!(source |> SquaredIntMapOperator(), logger())
;

# output

[LogActor] Data: 1
[LogActor] Data: 4
[LogActor] Data: 9
[LogActor] Completed

```

See also: [`AbstractOperator`](@ref), [`TypedOperator`](@ref),, [`ProxyObservable`](@ref), [`map`](@ref), [`logger`](@ref)
"""
macro CreateMapOperator(name, L, R, mappingFn)
    operatorName   = Symbol(name, "MapOperator")
    proxyName      = Symbol(name, "MapProxy")
    actorName      = Symbol(name, "MapActor")

    operatorDefinition = quote
        struct $operatorName <: Rocket.TypedOperator{$L, $R} end

        function Rocket.on_call!(::Type{$L}, ::Type{$R}, operator::($operatorName), source)
            return Rocket.proxy($R, source, ($proxyName)())
        end

        Base.show(io::IO, operator::($operatorName)) = print(io, string($operatorName), "(", string($L), " -> ", string($R), ")")
    end

    proxyDefinition = quote
        struct $proxyName <: Rocket.ActorProxy end

        Rocket.actor_proxy!(proxy::($proxyName), actor::A) where A = ($actorName){A}(actor)

        Base.show(io::IO, proxy::($proxyName)) = print(io, string($proxyName), "()")
    end

    actorDefinition = quote
        struct $actorName{A} <: Rocket.Actor{$L}
            actor :: A
        end

        Rocket.is_exhausted(actor::($actorName)) = Rocket.is_exhausted(actor.actor)

        Rocket.on_next!(actor::($actorName), data::($L))  = begin
            __inline_lambda = $mappingFn
            Rocket.next!(actor.actor, __inline_lambda(data))
        end

        Rocket.on_error!(actor::($actorName), err) = Rocket.error!(actor.actor, err)
        Rocket.on_complete!(actor::($actorName))   = Rocket.complete!(actor.actor)

        Base.show(io::IO, actor::($actorName)) = print(io, string($actorName), "()")
    end

    generated = quote
        $operatorDefinition
        $proxyDefinition
        $actorDefinition
    end

    return esc(generated)
end

macro CreateMapOperator(name, mappingFn)
    operatorName   = Symbol(name, "MapOperator")
    proxyName      = Symbol(name, "MapProxy")
    actorName      = Symbol(name, "MapActor")

    operatorDefinition = quote
        struct $operatorName{L, R} <: Rocket.TypedOperator{L, R} end

        function Rocket.on_call!(::Type{L}, ::Type{R}, operator::($operatorName){L, R}, source) where L where R
            return Rocket.proxy(R, source, ($proxyName){L}())
        end

        Base.show(io::IO, operator::($operatorName){L, R}) where L where R = print(io, string($operatorName), "(", L, " -> ", R, ")")
    end

    proxyDefinition = quote
        struct $proxyName{L} <: Rocket.ActorProxy end

        Rocket.actor_proxy!(proxy::($proxyName){L}, actor::A) where L where A = ($actorName){L, A}(actor)

        Base.show(io::IO, proxy::($proxyName){L}) where L = print(io, string($proxyName), "(", L, ")")
    end

    actorDefinition = quote
        struct $actorName{L, A} <: Rocket.Actor{L}
            actor :: A
        end

        Rocket.is_exhausted(a::($actorName)) = Rocket.is_exhausted(a.actor)

        Rocket.on_next!(a::($actorName){L}, data::L) where L  = begin
            __inlined_lambda = $mappingFn
            Rocket.next!(a.actor, __inlined_lambda(data))
        end

        Rocket.on_error!(a::($actorName), err) = Rocket.error!(a.actor, err)
        Rocket.on_complete!(a::($actorName))   = Rocket.complete!(a.actor)

        Base.show(io::IO, actor::($actorName){L}) where L = print(io, string($actorName), "(", L, ")")
    end

    generated = quote
        $operatorDefinition
        $proxyDefinition
        $actorDefinition
    end

    return esc(generated)
end
