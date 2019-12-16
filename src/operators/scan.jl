export scan
export ScanOperator, on_call!
export ScanProxy, actor_proxy!
export ScanActor, on_next!, on_error!, on_complete!
export @CreateScanOperator

"""
    scan(::Type{T}, ::Type{R}, scanFn::Function, initial::R = zero(R)) where T where R

Creates a scan operator, which applies a given accumulator `scanFn` function to each value emmited by the source
Observable, and returns each intermediate resultm with an optional initial value.

# Arguments
- `::Type{T}`: the type of data of source
- `::Type{R}`: the type of data of transformed value, may be or may not be the same as T
- `scanFn::Function`: accumulator function with `(data::T, current::R) -> R` signature
- `initial::R`: optional initial value for accumulator function

# Examples
```jldoctest
using Rx

source = from([ 1, 2, 3 ])
subscribe!(source |> scan(Int, Vector{Int}, (d, c) -> [ c..., d ], Int[]), LoggerActor{Vector{Int}}())
;

# output

[LogActor] Data: [1]
[LogActor] Data: [1, 2]
[LogActor] Data: [1, 2, 3]
[LogActor] Completed

```

See also: [`Operator`](@ref), ['ProxyObservable'](@ref)
"""
scan(::Type{T}, ::Type{R}, scanFn::Function, initial::R = zero(R)) where T where R = ScanOperator{T, R}(scanFn, initial)

struct ScanOperator{T, R} <: Operator{T, R}
    scanFn  :: Function
    initial :: R
end

function on_call!(operator::ScanOperator{T, R}, source::S) where { S <: Subscribable{T} } where T where R
    return ProxyObservable{R}(source, ScanProxy{T, R}(operator.scanFn, operator.initial))
end

struct ScanProxy{T, R} <: ActorProxy
    scanFn  :: Function
    initial :: R
end

actor_proxy!(proxy::ScanProxy{T, R}, actor::A) where { A <: AbstractActor{R} } where T where R = ScanActor{T, R, A}(proxy.scanFn, copy(proxy.initial), actor)

mutable struct ScanActor{T, R, A <: AbstractActor{R} } <: Actor{T}
    scanFn  :: Function
    current :: R
    actor   :: A
end

function on_next!(r::ScanActor{T, R, A}, data::T) where { A <: AbstractActor{R} } where T where R
    r.current = Base.invokelatest(r.scanFn, data, r.current)
    next!(r.actor, r.current)
end

on_error!(r::ScanActor, error) = error!(r.actor, error)
on_complete!(r::ScanActor)     = complete!(r.actor)


"""
    @CreateScanOperator(name, scanFn)

Creates a custom scan operator, which can be used as `nameScanOperator{T, R}()`.

# Arguments
- `name`: custom operator name
- `scanFn`: accumulator function, assumed to be pure

# Generates
- `nameScanOperator{T, R}()` function

# Examples
```jldoctest
using Rx

@CreateScanOperator(IntoArray, (d, c) -> [ c..., d ])

source = from([ 1, 2, 3 ])
subscribe!(source |> IntoArrayScanOperator{Int, Vector{Int}}(Int[]), LoggerActor{Vector{Int}}())
;

# output

[LogActor] Data: [1]
[LogActor] Data: [1, 2]
[LogActor] Data: [1, 2, 3]
[LogActor] Completed

```

"""
macro CreateScanOperator(name, scanFn)
    operatorName   = Symbol(name, "ScanOperator")
    proxyName      = Symbol(name, "ScanProxy")
    actorName      = Symbol(name, "ScanActor")

    operatorDefinition = quote
        struct $operatorName{T, R} <: Rx.Operator{T, R}
            initial :: R

            $(operatorName){T, R}(initial = zero(R)) where T where R = new(initial)
        end

        function Rx.on_call!(operator::($operatorName){T, R}, source::S) where { S <: Rx.Subscribable{T} } where T where R
            return Rx.ProxyObservable{R}(source, ($proxyName){T, R}(operator.initial))
        end
    end

    proxyDefinition = quote
        struct $proxyName{T, R} <: Rx.ActorProxy
            initial :: R
        end

        Rx.actor_proxy!(proxy::($proxyName){T, R}, actor::A) where { A <: Rx.AbstractActor{R} } where T where R = ($actorName){T, R, A}(copy(proxy.initial), actor)
    end

    actorDefinition = quote
        mutable struct $actorName{T, R, A <: Rx.AbstractActor{R} } <: Rx.Actor{T}
            current :: R
            actor   :: A
        end

        Rx.on_next!(actor::($actorName){T, R, A}, data::T) where { A <: Rx.AbstractActor{R} } where T where R = begin
            __inlined_lambda = $scanFn
            actor.current = __inlined_lambda(data, actor.current)
            Rx.next!(actor.actor, actor.current)
        end

        Rx.on_error!(actor::($actorName), error) = Rx.error!(actor.actor, error)
        Rx.on_complete!(actor::($actorName))     = Rx.complete!(actor.actor)
    end

    generated = quote
        $operatorDefinition
        $proxyDefinition
        $actorDefinition
    end

    return esc(generated)
end
