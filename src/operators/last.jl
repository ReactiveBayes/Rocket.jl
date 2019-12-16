export last
export LastOperator, on_call!
export LastProxy, actor_proxy!
export LastActor, on_next!, on_error!, on_complete!

import Base: last

"""
    last(::Type{T}, default = nothing) where T

Creates a last operator, which returns an Observable that emits only
the last item emitted by the source Observable.

# Arguments
- `::Type{T}`: the type of data of source
- `default`: an optional default value to provide if no values were emitted

# Examples
```jldoctest
using Rx

source = from([ 1, 2, 3 ])
subscribe!(source |> last(Int), LoggerActor{Int}())
;

# output

[LogActor] Data: 3
[LogActor] Completed

```

```jldoctest
using Rx

source = from(Int[])
subscribe!(source |> last(Int), LoggerActor{Int}())
;

# output

[LogActor] Completed
```

See also: [`Operator`](@ref), ['ProxyObservable'](@ref)
"""
last(::Type{T}, default = nothing) where T = LastOperator{T}(default)

struct LastOperator{T} <: Operator{T, T}
    default :: Union{Nothing, T}
end

function on_call!(operator::LastOperator{T}, source::S) where { S <: Subscribable{T} } where T
    return ProxyObservable{T}(source, LastProxy{T}(operator.default))
end

struct LastProxy{T} <: ActorProxy
    default :: Union{Nothing, T}
end

function actor_proxy!(proxy::LastProxy{T}, actor::A) where { A <: AbstractActor{T} } where T
    return LastActor{T}(proxy.default != nothing ? copy(proxy.default) : nothing, actor)
end

mutable struct LastActor{T} <: Actor{T}
    last   :: Union{Nothing, T}
    actor
end

function on_next!(actor::LastActor{T}, data::T) where T
    actor.last = data
end

on_error!(actor::LastActor{T}, error) where T = error!(actor.actor, error)

function on_complete!(actor::LastActor{T}) where T
    if actor.last != nothing
        next!(actor.actor, actor.last)
    end
    complete!(actor.actor)
end
