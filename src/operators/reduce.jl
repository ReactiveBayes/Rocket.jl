export reduce

import Base: reduce
import Base: show

"""
    reduce(::Type{R}, reduceFn::Function, seed::R) where R
    reduce(reduceFn::F) where { F <: Function }

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
using Rocket

source = from([ i for i in 1:10 ])
subscribe!(source |> reduce(Vector{Int}, (d, c) -> [ c..., d ], Int[]), logger())
;

# output

[LogActor] Data: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
[LogActor] Completed

```

```jldoctest
using Rocket

source = from([ i for i in 1:42 ])
subscribe!(source |> reduce(+), logger())
;

# output

[LogActor] Data: 903
[LogActor] Completed

```

See also: [`AbstractOperator`](@ref), [`RightTypedOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
reduce(::Type{R}, reduceFn::F, seed::R) where { R, F <: Function } = ReduceOperator{R, F}(reduceFn, seed)

# ------------------------------------------------------------------------------------------------ #
# Seed version of reduce operator (typed with R also)
# ------------------------------------------------------------------------------------------------ #

struct ReduceOperator{R, F} <: RightTypedOperator{R}
    reduceFn :: F
    seed     :: R
end

function on_call!(::Type{L}, ::Type{R}, operator::ReduceOperator{R, F}, source) where { L, R, F }
    return proxy(R, source, ReduceProxy{L, R, F}(operator.reduceFn, operator.seed))
end

struct ReduceProxy{L, R, F} <: ActorProxy
    reduceFn :: F
    seed     :: R
end

actor_proxy!(::Type{R}, proxy::ReduceProxy{L, R, F}, actor::A) where { L, R, A, F } = ReduceActor{L, R, A, F}(proxy.reduceFn, actor, proxy.seed)

mutable struct ReduceActor{L, R, A, F} <: Actor{L}
    reduceFn :: F
    actor    :: A
    current  :: R
end

getcurrent(actor::ReduceActor)         = actor.current
setcurrent!(actor::ReduceActor, value) = actor.current = value

function on_next!(actor::ReduceActor{L, R}, data::L) where { L, R }
    setcurrent!(actor, actor.reduceFn(data, getcurrent(actor)))
end

function on_error!(actor::ReduceActor, err)
    error!(actor.actor, err)
end

function on_complete!(actor::ReduceActor)
    next!(actor.actor, getcurrent(actor))
    complete!(actor.actor)
end

Base.show(io::IO, ::ReduceOperator{R}) where R = print(io, "ReduceOperator( -> $R)")
Base.show(io::IO, ::ReduceProxy{L})    where L = print(io, "ReduceProxy($L)")
Base.show(io::IO, ::ReduceActor{L})    where L = print(io, "ReduceActor($L)")

# ------------------------------------------------------------------------------------------------ #
# No seed version of reduce operator (output data stream type is inferred from input)
# ------------------------------------------------------------------------------------------------ #

reduce(reduceFn::F) where { F <: Function } = ReduceNoSeedOperator{F}(reduceFn)

struct ReduceNoSeedOperator{F} <: InferableOperator
    reduceFn :: F
end

operator_right(operator::ReduceNoSeedOperator, ::Type{L}) where L = L

function on_call!(::Type{L}, ::Type{L}, operator::ReduceNoSeedOperator{F}, source) where { L, F }
    return proxy(L, source, ReduceNoSeedProxy{F}(operator.reduceFn))
end

struct ReduceNoSeedProxy{F} <: ActorProxy
    reduceFn :: F
end

actor_proxy!(::Type{L}, proxy::ReduceNoSeedProxy{F}, actor::A) where { L, A, F } = ReduceNoSeedActor{L, A, F}(proxy.reduceFn, actor, nothing)

mutable struct ReduceNoSeedActor{L, A, F} <: Actor{L}
    reduceFn :: F
    actor    :: A
    current  :: Union{L, Nothing}
end

getcurrent(actor::ReduceNoSeedActor)         = actor.current
setcurrent!(actor::ReduceNoSeedActor, value) = actor.current = value

function on_next!(actor::ReduceNoSeedActor{L}, data::L) where L
    current = getcurrent(actor)
    if current === nothing
        setcurrent!(actor, data)
    else
        setcurrent!(actor, actor.reduceFn(data, current))
    end
end

function on_error!(actor::ReduceNoSeedActor, err)
    error!(actor.actor, err)
end

function on_complete!(actor::ReduceNoSeedActor)
    current = getcurrent(actor)
    if current !== nothing
        next!(actor.actor, current)
    end
    complete!(actor.actor)
end

Base.show(io::IO, ::ReduceNoSeedOperator)         = print(io, "ReduceNoSeedOperator(L -> L)")
Base.show(io::IO, ::ReduceNoSeedProxy)            = print(io, "ReduceNoSeedProxy()")
Base.show(io::IO, ::ReduceNoSeedActor{L}) where L = print(io, "ReduceNoSeedActor($L)")
