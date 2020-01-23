export last
export LastOperator, on_call!
export LastProxy, actor_proxy!
export LastActor, on_next!, on_error!, on_complete!, is_exhausted

import Base: last

"""
    last(; default = nothing)

Creates a last operator, which returns an Observable that emits only
the last item emitted by the source Observable.

# Arguments
- `default`: an optional default value to provide if no values were emitted

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream

# Examples
```jldoctest
using Rx

source = from([ 1, 2, 3 ])
subscribe!(source |> last(), LoggerActor{Int}())
;

# output

[LogActor] Data: 3
[LogActor] Completed

```

```jldoctest
using Rx

source = from(Int[])
subscribe!(source |> last(), LoggerActor{Int}())
;

# output

[LogActor] Completed
```

```jldoctest
using Rx

source = Rx.from(Int[])
subscribe!(source |> last(default = 1), LoggerActor{Int}())
;

# output

[LogActor] Data: 1
[LogActor] Completed
```

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref)
"""
last(; default = nothing) = LastOperator(default)

struct LastOperator <: InferableOperator
    default
end

function on_call!(::Type{L}, ::Type{L}, operator::LastOperator, source) where L
    return ProxyObservable{L}(source, LastProxy{L}(operator.default))
end

operator_right(operator::LastOperator, ::Type{L}) where L = L

struct LastProxy{L} <: ActorProxy
    default :: Union{L, Nothing}
end

actor_proxy!(proxy::LastProxy{L}, actor::A) where L where A = LastActor{L, A}(proxy.default, actor)

mutable struct LastActor{L, A} <: Actor{L}
    last   :: Union{L, Nothing}
    actor  :: A
end

is_exhausted(actor::LastActor) = is_exhausted(actor.actor)

function on_next!(actor::LastActor{L}, data::L) where L
    actor.last = data
end

function on_error!(actor::LastActor, err)
    error!(actor.actor, error)
end

function on_complete!(actor::LastActor)
    if actor.last !== nothing
        next!(actor.actor, actor.last)
    end
    complete!(actor.actor)
end
