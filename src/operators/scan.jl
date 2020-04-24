export scan

import Base: show

"""
    scan(::Type{R}, scanFn::F, seed::R) where { R, F <: Function }
    scan(scanFn::F) where { F <: Function }

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
subscribe!(source |> scan(+), logger())
;

# output

[LogActor] Data: 1
[LogActor] Data: 3
[LogActor] Data: 6
[LogActor] Completed

```

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
scan(::Type{R}, scanFn::F, seed::R) where { R, F <: Function } = ScanOperator{R, F}(scanFn, seed)

# ------------------------------------------------------------------------------------------------ #
# Seed version of scan operator (typed with R also)
# ------------------------------------------------------------------------------------------------ #

struct ScanOperator{R, F} <: RightTypedOperator{R}
    scanFn  :: F
    seed    :: R
end

function on_call!(::Type{L}, ::Type{R}, operator::ScanOperator{R, F}, source) where { L, R, F }
    return proxy(R, source, ScanProxy{L, R, F}(operator.scanFn, operator.seed))
end

struct ScanProxy{L, R, F} <: ActorProxy
    scanFn  :: F
    seed    :: R
end

actor_proxy!(proxy::ScanProxy{L, R, F}, actor::A) where { L, R, A, F } = ScanActor{L, R, A, F}(proxy.scanFn, proxy.seed, actor)

mutable struct ScanActor{L, R, A, F} <: Actor{L}
    scanFn  :: F
    current :: R
    actor   :: A
end

is_exhausted(actor::ScanActor) = is_exhausted(actor.actor)

function on_next!(actor::ScanActor{L, R}, data::L) where { L, R }
    actor.current = actor.scanFn(data, actor.current)
    next!(actor.actor, actor.current)
end

on_error!(actor::ScanActor, err) = error!(actor.actor, err)
on_complete!(actor::ScanActor)   = complete!(actor.actor)

Base.show(io::IO, ::ScanOperator{R}) where R = print(io, "ScanOperator( -> $R)")
Base.show(io::IO, ::ScanProxy{L})    where L = print(io, "ScanProxy($L)")
Base.show(io::IO, ::ScanActor{L})    where L = print(io, "ScanActor($L)")

# ------------------------------------------------------------------------------------------------ #
# No seed version of scan operator (output data stream type is inferred from input)
# ------------------------------------------------------------------------------------------------ #

scan(scanFn::F) where { F <: Function } = ScanNoSeedOperator{F}(scanFn)

struct ScanNoSeedOperator{F} <: InferableOperator
    scanFn  :: F
end

operator_right(operator::ScanNoSeedOperator, ::Type{L}) where L = L

function on_call!(::Type{L}, ::Type{L}, operator::ScanNoSeedOperator{F}, source) where { L, F }
    return proxy(L, source, ScanNoSeedProxy{L, F}(operator.scanFn))
end

struct ScanNoSeedProxy{L, F} <: ActorProxy
    scanFn  :: F
end

actor_proxy!(proxy::ScanNoSeedProxy{L, F}, actor::A) where { L, A, F } = ScanNoSeedActor{L, A, F}(proxy.scanFn, nothing, actor)

mutable struct ScanNoSeedActor{L, A, F} <: Actor{L}
    scanFn  :: F
    current :: Union{L, Nothing}
    actor   :: A
end

is_exhausted(actor::ScanNoSeedActor) = is_exhausted(actor.actor)

function on_next!(actor::ScanNoSeedActor{L}, data::L) where { L }
    if actor.current === nothing
        actor.current = data
    else
        actor.current = actor.scanFn(data, actor.current)
    end
    next!(actor.actor, actor.current)
end

on_error!(actor::ScanNoSeedActor, err) = error!(actor.actor, err)
on_complete!(actor::ScanNoSeedActor)   = complete!(actor.actor)

Base.show(io::IO, ::ScanNoSeedOperator)         = print(io, "ScanNoSeedOperator(L -> L)")
Base.show(io::IO, ::ScanNoSeedProxy{L}) where L = print(io, "ScanNoSeedProxy($L)")
Base.show(io::IO, ::ScanNoSeedActor{L}) where L = print(io, "ScanNoSeedActor($L)")
