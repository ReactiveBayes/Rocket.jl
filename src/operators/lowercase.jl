export lowercase

import Base: lowercase
import Base: show

"""
    lowercase()

Creates an lowercase operator, which forces each value to be in lower case

# Producing

Stream of type `<: Subscribable{L}` where L referes to type of data of input Observable

# Examples

```jldoctest
using Rocket

source = of("Hello, world!")
subscribe!(source |> lowercase(), logger())
;

# output

[LogActor] Data: hello, world!
[LogActor] Completed
```

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
lowercase() = LowercaseOperator()

struct LowercaseOperator <: InferableOperator end

function on_call!(::Type{L}, ::Type{L}, operator::LowercaseOperator, source) where {L}
    return proxy(L, source, LowercaseProxy())
end

operator_right(::LowercaseOperator, ::Type{L}) where {L} = L

struct LowercaseProxy <: ActorProxy end

actor_proxy!(::Type{L}, proxy::LowercaseProxy, actor::A) where {L,A} =
    LowercaseActor{L,A}(actor)

struct LowercaseActor{L,A} <: Actor{L}
    actor::A
end

on_next!(actor::LowercaseActor{L}, data::L) where {L} = next!(actor.actor, lowercase(data))
on_error!(actor::LowercaseActor, err) = error!(actor.actor, err)
on_complete!(actor::LowercaseActor) = complete!(actor.actor)

Base.show(io::IO, ::LowercaseOperator) = print(io, "LowercaseOperator()")
Base.show(io::IO, ::LowercaseProxy) = print(io, "LowercaseProxy()")
Base.show(io::IO, ::LowercaseActor{L}) where {L} = print(io, "LowercaseActor($L)")
