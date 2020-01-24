export reduce
export ReduceOperator, on_call!
export ReduceProxy, actor_proxy!
export ReduceActor, on_next!, on_error!, on_complete!, is_exhausted
export @CreateReduceOperator

import Base: reduce
import Base: show

"""
    reduce(::Type{R}, reduceFn::Function, seed::Union{R, Nothing} = nothing) where R

Creates a reduce operator, which applies a given accumulator `reduceFn` function
over the source Observable, and returns the accumulated result when the source completes,
given an optional seed value. If a `seed` value is specified, then that value will be used as
the initial value for the accumulator. If no `seed` value is specified, the first item of the source is used as the seed.

# Arguments
- `::Type{R}`: the type of data of transformed value
- `reduceFn::Function`: transformation function with `(data::T, current::R) -> R` signature
- `seed::R`: optional seed accumulation value

# Producing

Stream of type `<: Subscribable{R}`

# Examples
```jldoctest
using Rx

source = from([ i for i in 1:10 ])
subscribe!(source |> reduce(Vector{Int}, (d, c) -> [ c..., d ], Int[]), logger())
;

# output

[LogActor] Data: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
[LogActor] Completed

```

```jldoctest
using Rx

source = from([ i for i in 1:42 ])
subscribe!(source |> reduce(Int, +), logger())
;

# output

[LogActor] Data: 903
[LogActor] Completed

```

See also: [`AbstractOperator`](@ref), [`RightTypedOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
reduce(::Type{R}, reduceFn::Function, seed::Union{R, Nothing} = nothing) where R = ReduceOperator{R}(reduceFn, seed)

struct ReduceOperator{R} <: RightTypedOperator{R}
    reduceFn :: Function
    seed     :: Union{R, Nothing}
end

function on_call!(::Type{L}, ::Type{R}, operator::ReduceOperator{R}, source) where L where R
    return proxy(R, source, ReduceProxy{L, R}(operator.reduceFn, operator.seed))
end

struct ReduceProxy{L, R} <: ActorProxy
    reduceFn :: Function
    seed     :: Union{R, Nothing}
end

actor_proxy!(proxy::ReduceProxy{L, R}, actor::A) where L where R where A = ReduceActor{L, R, A}(proxy.reduceFn, proxy.seed, actor)

mutable struct ReduceActor{L, R, A} <: Actor{L}
    reduceFn :: Function
    current  :: Union{R, Nothing}
    actor    :: A
end

is_exhausted(actor::ReduceActor) = is_exhausted(actor.actor)

function on_next!(actor::ReduceActor{L, R}, data::L) where L where R
    if actor.current === nothing
        actor.current = data
    else
        actor.current = actor.reduceFn(data, actor.current)
    end
end

function on_error!(actor::ReduceActor, err)
    error!(actor.actor, err)
end

function on_complete!(actor::ReduceActor)
    next!(actor.actor, actor.current)
    complete!(actor.actor)
end

Base.show(io::IO, operator::ReduceOperator{R}) where R   = print(io, "ReduceOperator( -> $R)")
Base.show(io::IO, proxy::ReduceProxy{L})       where L   = print(io, "ReduceProxy($L)")
Base.show(io::IO, actor::ReduceActor{L})       where L   = print(io, "ReduceActor($L)")

"""
    @CreateReduceOperator(name, L, R, reduceFn)

Creates a custom reduce operator, which can be used as `nameReduceOperator()`.

# Arguments
- `name`: custom operator name
- `L`: type of input data
- `R`: type of output data after `reduceFn` projection
- `reduceFn`: accumulator function, assumed to be pure

# Generates
- `nameReduceOperator(seed::R)` function

# Producing

Stream of type `<: Subscribable{R}`

# Examples
```jldoctest
using Rx

@CreateReduceOperator(IntoArray, Int, Vector{Int}, (d, c) -> [ c..., d ])

source = from([ 1, 2, 3 ])
subscribe!(source |> IntoArrayReduceOperator(Int[]), logger())
;

# output

[LogActor] Data: [1, 2, 3]
[LogActor] Completed

```

See also: [`AbstractOperator`](@ref), [`TypedOperator`](@ref), [`ProxyObservable`](@ref), [`reduce`](@ref), [`logger`](@ref)
"""
macro CreateReduceOperator(name, L, R, reduceFn)
    operatorName   = Symbol(name, "ReduceOperator")
    proxyName      = Symbol(name, "ReduceProxy")
    actorName      = Symbol(name, "ReduceActor")

    operatorDefinition = quote
        struct $operatorName <: Rx.TypedOperator{$L, $R}
            seed :: $R
        end

        function Rx.on_call!(::Type{$L}, ::Type{$R}, operator::($operatorName), source)
            return Rx.proxy($R, source, ($proxyName)(operator.seed))
        end

        Base.show(io::IO, operator::($operatorName)) = print(io, string($operatorName), "(", string($L), " -> ", string($R), ")")
    end

    proxyDefinition = quote
        struct $proxyName <: ActorProxy
            seed :: $R
        end

        Rx.actor_proxy!(proxy::($proxyName), actor::A) where A = ($actorName){A}(proxy.seed, actor)

        Base.show(io::IO, proxy::($proxyName)) = print(io, string($proxyName), "()")
    end

    actorDefinition = quote
        mutable struct $actorName{A} <: Rx.Actor{$L}
            current :: $R
            actor   :: A
        end

        Rx.is_exhausted(actor::($actorName)) = is_exhausted(actor.actor)

        Rx.on_next!(actor::($actorName), data::($L)) = begin
            __inlined_lambda = $reduceFn
            actor.current = __inlined_lambda(data, actor.current)
        end

        Rx.on_error!(actor::($actorName), err) = begin
            Rx.error!(actor.actor, err)
        end

        Rx.on_complete!(actor::($actorName))   = begin
            Rx.next!(actor.actor, actor.current)
            Rx.complete!(actor.actor)
        end

        Base.show(io::IO, actor::($actorName)) = print(io, string($actorName), "()")
    end

    generated = quote
        $operatorDefinition
        $proxyDefinition
        $actorDefinition
    end

    return esc(generated)
end
