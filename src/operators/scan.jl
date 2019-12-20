export scan
export ScanOperator, on_call!
export ScanProxy, actor_proxy!
export ScanActor, on_next!, on_error!, on_complete!
export @CreateScanOperator

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
using Rx

source = from([ 1, 2, 3 ])
subscribe!(source |> scan(Vector{Int}, (d, c) -> [ c..., d ], Int[]), LoggerActor{Vector{Int}}())
;

# output

[LogActor] Data: [1]
[LogActor] Data: [1, 2]
[LogActor] Data: [1, 2, 3]
[LogActor] Completed

```

See also: [`AbstractOperator`](@ref), [`RightTypedOperator`](@ref), [`ProxyObservable`](@ref), [`reduce`](@ref)
"""
scan(::Type{R}, scanFn::Function, seed::Union{R, Nothing} = nothing) where T where R = ScanOperator{R}(scanFn, seed)

struct ScanOperator{R} <: RightTypedOperator{R}
    scanFn  :: Function
    seed    :: Union{R, Nothing}
end

function on_call!(::Type{L}, ::Type{R}, operator::ScanOperator{R}, source) where L where R
    return ProxyObservable{R}(source, ScanProxy{L, R}(operator.scanFn, operator.seed))
end

struct ScanProxy{L, R} <: ActorProxy
    scanFn  :: Function
    seed    :: Union{R, Nothing}
end

actor_proxy!(proxy::ScanProxy{L, R}, actor::A) where { A <: AbstractActor{R} } where L where R = ScanActor{L, R, A}(proxy.scanFn, proxy.seed, actor)

mutable struct ScanActor{L, R, A <: AbstractActor{R} } <: Actor{L}
    scanFn  :: Function
    current :: Union{R, Nothing}
    actor   :: A
end

function on_next!(r::ScanActor{L, R, A}, data::L) where { A <: AbstractActor{R} } where L where R
    if r.current == nothing
        r.current = data
    else
        r.current = Base.invokelatest(r.scanFn, data, r.current)
    end
    next!(r.actor, r.current)
end

on_error!(r::ScanActor{L, R, A}, err) where { A <: AbstractActor{R} } where L where R = error!(r.actor, err)
on_complete!(r::ScanActor{L, R, A})   where { A <: AbstractActor{R} } where L where R = complete!(r.actor)


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
using Rx

@CreateScanOperator(IntoArray, Int, Vector{Int}, (d, c) -> [ c..., d ])

source = from([ 1, 2, 3 ])
subscribe!(source |> IntoArrayScanOperator(Int[]), LoggerActor{Vector{Int}}())
;

# output

[LogActor] Data: [1]
[LogActor] Data: [1, 2]
[LogActor] Data: [1, 2, 3]
[LogActor] Completed

```

See also: [`AbstractOperator`](@ref), [`TypedOperator`](@ref), [`ProxyObservable`](@ref), [`scan`](@ref)
"""
macro CreateScanOperator(name, L, R, scanFn)
    operatorName   = Symbol(name, "ScanOperator")
    proxyName      = Symbol(name, "ScanProxy")
    actorName      = Symbol(name, "ScanActor")

    operatorDefinition = quote
        struct $operatorName <: Rx.TypedOperator{$L, $R}
            seed :: $R
        end

        function Rx.on_call!(::Type{$L}, ::Type{$R}, operator::($operatorName), source::S) where { S <: Rx.Subscribable{$L} }
            return Rx.ProxyObservable{$R}(source, ($proxyName)(operator.seed))
        end
    end

    proxyDefinition = quote
        struct $proxyName <: Rx.ActorProxy
            seed :: $R
        end

        Rx.actor_proxy!(proxy::($proxyName), actor::A) where { A <: Rx.AbstractActor{$R} } = ($actorName){A}(proxy.seed, actor)
    end

    actorDefinition = quote
        mutable struct $actorName{ A <: Rx.AbstractActor{$R} } <: Rx.Actor{$L}
            current :: $R
            actor   :: A
        end

        Rx.on_next!(actor::($actorName){A}, data::($L)) where { A <: Rx.AbstractActor{$R} } = begin
            __inlined_lambda = $scanFn
            actor.current = __inlined_lambda(data, actor.current)
            Rx.next!(actor.actor, actor.current)
        end

        Rx.on_error!(actor::($actorName), err) = Rx.error!(actor.actor, err)
        Rx.on_complete!(actor::($actorName))   = Rx.complete!(actor.actor)
    end

    generated = quote
        $operatorDefinition
        $proxyDefinition
        $actorDefinition
    end

    return esc(generated)
end
