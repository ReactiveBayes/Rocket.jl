export scan
export @CreateScanOperator

import Base: show

"""
    scan(::Type{R}, scanFn::Function, seed::Union{R, Nothing} = nothing) where R

Creates a scan operator, which applies a given accumulator `scanFn` function to each value emmited by the source
Observable, and returns each intermediate result with an optional seed value. If a seed value is specified,
then that value will be used as the initial value for the accumulator.
If no seed value is specified, the first item of the source is used as the seed.

# Arguments
- `::Type{R}`: the type of data of transformed value, may be or may not be the same as type of input source
- `scanFn::Function`: accumulator function with `(data::T, current::R) -> R` signature
- `seed::R`: optional initial value for accumulator function

# Producing

Stream of type `<: Subscribable{R}`

# Examples
```jldoctest
using Rocket

source = from([ 1, 2, 3 ])
subscribe!(source |> scan(Vector{Int}, (d, c) -> [ c..., d ], Int[]), logger())
;

# output

[LogActor] Data: [1]
[LogActor] Data: [1, 2]
[LogActor] Data: [1, 2, 3]
[LogActor] Completed

```

See also: [`AbstractOperator`](@ref), [`RightTypedOperator`](@ref), [`ProxyObservable`](@ref), [`reduce`](@ref), [`logger`](@ref)
"""
scan(::Type{R}, scanFn::Function, seed::Union{R, Nothing} = nothing) where T where R = ScanOperator{R}(scanFn, seed)

struct ScanOperator{R} <: RightTypedOperator{R}
    scanFn  :: Function
    seed    :: Union{R, Nothing}
end

function on_call!(::Type{L}, ::Type{R}, operator::ScanOperator{R}, source) where L where R
    return proxy(R, source, ScanProxy{L, R}(operator.scanFn, operator.seed))
end

struct ScanProxy{L, R} <: ActorProxy
    scanFn  :: Function
    seed    :: Union{R, Nothing}
end

actor_proxy!(proxy::ScanProxy{L, R}, actor::A) where L where R where A = ScanActor{L, R, A}(proxy.scanFn, proxy.seed, actor)

mutable struct ScanActor{L, R, A} <: Actor{L}
    scanFn  :: Function
    current :: Union{R, Nothing}
    actor   :: A
end

is_exhausted(actor::ScanActor) = is_exhausted(actor.actor)

function on_next!(r::ScanActor{L, R}, data::L) where L where R
    if r.current === nothing
        r.current = data
    else
        r.current = r.scanFn(data, r.current)
    end
    next!(r.actor, r.current)
end

on_error!(r::ScanActor, err) where L where R = error!(r.actor, err)
on_complete!(r::ScanActor)   where L where R = complete!(r.actor)

Base.show(io::IO, operator::ScanOperator{R}) where R   = print(io, "ScanOperator( -> $R)")
Base.show(io::IO, proxy::ScanProxy{L})       where L   = print(io, "ScanProxy($L)")
Base.show(io::IO, actor::ScanActor{L})       where L   = print(io, "ScanActor($L)")

"""
    @CreateScanOperator(name, L, R, scanFn)

Creates a custom scan operator, which can be used as `nameScanOperator()`.

# Arguments
- `name`: custom operator name
- `L`: type of input data
- `R`: type of output data after `scanFn` projection
- `scanFn`: accumulator function, assumed to be pure

# Generates
- `nameScanOperator(seed::R)` function

# Producing

Stream of type `<: Subscribable{R}`

# Examples
```jldoctest
using Rocket

@CreateScanOperator(IntoArray, Int, Vector{Int}, (d, c) -> [ c..., d ])

source = from([ 1, 2, 3 ])
subscribe!(source |> IntoArrayScanOperator(Int[]), logger())
;

# output

[LogActor] Data: [1]
[LogActor] Data: [1, 2]
[LogActor] Data: [1, 2, 3]
[LogActor] Completed

```

See also: [`AbstractOperator`](@ref), [`TypedOperator`](@ref), [`ProxyObservable`](@ref), [`scan`](@ref), [`logger`](@ref)
"""
macro CreateScanOperator(name, L, R, scanFn)
    operatorName   = Symbol(name, "ScanOperator")
    proxyName      = Symbol(name, "ScanProxy")
    actorName      = Symbol(name, "ScanActor")

    operatorDefinition = quote
        struct $operatorName <: Rocket.TypedOperator{$L, $R}
            seed :: $R
        end

        function Rocket.on_call!(::Type{$L}, ::Type{$R}, operator::($operatorName), source)
            return Rocket.proxy($R, source, ($proxyName)(operator.seed))
        end

        Base.show(io::IO, operator::($operatorName)) = print(io, string($operatorName), "(", string($L), " -> ", string($R), ")")
    end

    proxyDefinition = quote
        struct $proxyName <: Rocket.ActorProxy
            seed :: $R
        end

        Rocket.actor_proxy!(proxy::($proxyName), actor::A) where A = ($actorName){A}(proxy.seed, actor)

        Base.show(io::IO, proxy::($proxyName)) = print(io, string($proxyName), "()")
    end

    actorDefinition = quote
        mutable struct $actorName{A} <: Rocket.Actor{$L}
            current :: $R
            actor   :: A
        end

        Rocket.is_exhausted(actor::($actorName)) = is_exhausted(actor.actor)

        Rocket.on_next!(actor::($actorName), data::($L)) = begin
            __inlined_lambda = $scanFn
            actor.current = __inlined_lambda(data, actor.current)
            Rocket.next!(actor.actor, actor.current)
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
