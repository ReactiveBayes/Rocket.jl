export last
export LastOperator, on_call!
export LastProxy, actor_proxy!
export LastActor, on_next!, on_error!, on_complete!

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

function on_call!(::Type{L}, ::Type{L}, operator::LastOperator, source::S) where { S <: Subscribable{L} } where L
    return ProxyObservable{L}(source, LastProxy{L}(operator.default))
end

operator_right(operator::LastOperator, ::Type{L}) where L = L

struct LastProxy{L} <: ActorProxy
    default :: Union{L, Nothing}
end

function actor_proxy!(proxy::LastProxy{L}, actor::A) where { A <: AbstractActor{L} } where L
    return LastActor{L, A}(proxy.default, actor)
end

mutable struct LastActor{L, A <: AbstractActor{L} } <: Actor{L}
    last   :: Union{L, Nothing}
    actor  :: A
end

function on_next!(actor::LastActor{L, A}, data::L) where { A <: AbstractActor{L} } where L
    actor.last = data
end

function on_error!(actor::LastActor, err)
    error!(actor.actor, error)
end

function on_complete!(actor::LastActor)
    if actor.last != nothing
        next!(actor.actor, actor.last)
    end
    complete!(actor.actor)
end
