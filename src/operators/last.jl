export last, LastNotFoundException

import Base: last
import Base: show

struct LastNotFoundException <: Exception end

"""
    last(; default = nothing)

Creates a last operator, which returns an Observable that emits only
the last item emitted by the source Observable.
Sends `LastNotFoundException` error message if a given source completes without emitting a single value.

# Arguments
- `default`: an optional default value to provide if no values were emitted

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream

# Examples
```jldoctest
using Rocket

source = from([ 1, 2, 3 ])
subscribe!(source |> last(), logger())
;

# output

[LogActor] Data: 3
[LogActor] Completed

```

```jldoctest
using Rocket

source = from(Int[])
subscribe!(source |> last() |> catch_error((err, obs) -> of(1)), logger())
;

# output

[LogActor] Data: 1
[LogActor] Completed
```

```jldoctest
using Rocket

source = from(Int[])
subscribe!(source |> last(default = 1), logger())
;

# output

[LogActor] Data: 1
[LogActor] Completed
```

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
last(; default::D = nothing) where D = LastOperator{D}(default)

struct LastOperator{D} <: InferableOperator
    default :: D
end

function on_call!(::Type{L}, ::Type{R}, operator::LastOperator, source) where { L, R }
    return proxy(R, source, LastProxy{R}(operator.default))
end

operator_right(operator::LastOperator{Nothing}, ::Type{L}) where L        = L
operator_right(operator::LastOperator{D},       ::Type{L}) where { L, D } = Union{L, D}

struct LastProxy{L} <: ActorProxy
    default :: Union{L, Nothing}
end

actor_proxy!(proxy::LastProxy{L}, actor::A) where { L, A } = LastActor{L, A}(proxy.default, actor)

mutable struct LastActor{L, A} <: Actor{L}
    last   :: Union{L, Nothing}
    actor  :: A
end

function on_next!(actor::LastActor{L}, data::L) where L
    actor.last = data
end

function on_error!(actor::LastActor, err)
    error!(actor.actor, err)
end

function on_complete!(actor::LastActor)
    if actor.last !== nothing
        next!(actor.actor, actor.last)
        complete!(actor.actor)
    else
        error!(actor.actor, LastNotFoundException())
    end
end

Base.show(io::IO, ::LastOperator)         = print(io, "LastOperator()")
Base.show(io::IO, ::LastProxy{L}) where L = print(io, "LastProxy($L)")
Base.show(io::IO, ::LastActor{L}) where L = print(io, "LastActor($L)")
