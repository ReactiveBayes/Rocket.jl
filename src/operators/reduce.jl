export reduce
export ReduceOperator, on_call!
export ReduceProxy, actor_proxy!
export ReduceActor, on_next!, on_error!, on_complete!
export @CreateReduceOperator

import Base: reduce

"""
    reduce(::Type{T}, ::Type{R}, reduceFn::Function, initial::R = zero(R)) where T where R

Creates a reduce operator, which applies a given accumulator `reduceFn` function
over the source Observable, and returns the accumulated result when the source completes,
given an optional initial value.


# Arguments
- `::Type{T}`: the type of data of source
- `::Type{R}`: the type of data of transformed value, may be or may not be the same as T
- `reduceFn::Function`: transformation function with `(data::T) -> R` signature
- `initial::R`: optional initial accumulation value

# Examples
```jldoctest
using Rx

source = from([ i for i in 1:10 ])
subscribe!(source |> reduce(Int, Vector{Int}, (d, c) -> [ c..., d ], Int[]), LoggerActor{Vector{Int}}())
;

# output

[LogActor] Data: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
[LogActor] Completed

```

```jldoctest
using Rx

source = from([ i for i in 1:42 ])
subscribe!(source |> reduce(Int, Int, +), LoggerActor{Int}())
;

# output

[LogActor] Data: 903
[LogActor] Completed

```

See also: [`Operator`](@ref), ['ProxyObservable'](@ref)
"""
reduce(::Type{T}, ::Type{R}, reduceFn::Function, initial::R = zero(R)) where T where R = ReduceOperator{T, R}(reduceFn, initial)

struct ReduceOperator{T, R} <: Operator{T, R}
    reduceFn :: Function
    initial  :: R
end

function on_call!(operator::ReduceOperator{T, R}, source::S) where { S <: Subscribable{T} } where T where R
    return ProxyObservable{R}(source, ReduceProxy{T, R}(operator.reduceFn, operator.initial))
end

struct ReduceProxy{T, R} <: ActorProxy
    reduceFn :: Function
    initial  :: R
end

actor_proxy!(proxy::ReduceProxy{T, R}, actor::A) where { A <: AbstractActor{R} } where T where R = ReduceActor{T, R, A}(proxy.reduceFn, copy(proxy.initial), actor)

mutable struct ReduceActor{T, R, A <: AbstractActor{R} } <: Actor{T}
    reduceFn :: Function
    current  :: R
    actor    :: A
end

function on_next!(actor::ReduceActor{T, R, A}, data::T) where { A <: AbstractActor{R} } where T where R
    actor.current = Base.invokelatest(actor.reduceFn, data, actor.current)
end

on_error!(actor::ReduceActor, error) = error!(actor.actor, error)

function on_complete!(actor::ReduceActor)
    next!(actor.actor, actor.current)
    complete!(actor.actor)
end

"""
    @CreateReduceOperator(name, reduceFn)

Creates a custom reduce operator, which can be used as `nameReduceOperator{T, R}()`.

# Arguments
- `name`: custom operator name
- `reduceFn`: accumulator function, assumed to be pure

# Generates
- `nameReduceOperator{T, R}()` function

# Examples
```jldoctest
using Rx

@CreateReduceOperator(IntoArray, (d, c) -> [ c..., d ])

source = from([ 1, 2, 3 ])
subscribe!(source |> IntoArrayReduceOperator{Int, Vector{Int}}(Int[]), LoggerActor{Vector{Int}}())
;

# output

[LogActor] Data: [1, 2, 3]
[LogActor] Completed

```

"""
macro CreateReduceOperator(name, reduceFn)
    operatorName   = Symbol(name, "ReduceOperator")
    proxyName      = Symbol(name, "ReduceProxy")
    actorName      = Symbol(name, "ReduceActor")

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
        struct $proxyName{T, R} <: ActorProxy
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
            __inlined_lambda = $reduceFn
            actor.current = __inlined_lambda(data, actor.current)
        end

        Rx.on_error!(actor::($actorName), error) = Rx.error!(actor.actor, error)
        Rx.on_complete!(actor::($actorName))     = begin
            Rx.next!(actor.actor, actor.current)
            Rx.complete!(actor.actor)
        end
    end

    generated = quote
        $operatorDefinition
        $proxyDefinition
        $actorDefinition
    end

    return esc(generated)
end
