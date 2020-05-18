export uppercase

import Base: uppercase
import Base: show

"""
    uppercase()

Creates an uppercase operator, which forces each value to be in upper case

# Producing

Stream of type `<: Subscribable{L}` where L referes to type of data of input Observable

# Examples

```jldoctest
using Rocket

source = of("Hello, world!")
subscribe!(source |> uppercase(), logger())
;

# output

[LogActor] Data: HELLO, WORLD!
[LogActor] Completed
```

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
uppercase() = UppercaseOperator()

struct UppercaseOperator <: InferableOperator end

function on_call!(::Type{L}, ::Type{L}, operator::UppercaseOperator, source) where L
    return proxy(L, source, UppercaseProxy())
end

operator_right(::UppercaseOperator, ::Type{L}) where L = L

struct UppercaseProxy <: ActorProxy end

actor_proxy!(::Type{L}, proxy::UppercaseProxy, actor::A) where { L, A } = UppercaseActor{L, A}(actor)

struct UppercaseActor{L, A} <: Actor{L}
    actor :: A
end

on_next!(actor::UppercaseActor{L}, data::L) where L = next!(actor.actor, uppercase(data))
on_error!(actor::UppercaseActor, err)               = error!(actor.actor, err)
on_complete!(actor::UppercaseActor)                 = complete!(actor.actor)

Base.show(io::IO, ::UppercaseOperator)         = print(io, "UppercaseOperator()")
Base.show(io::IO, ::UppercaseProxy)            = print(io, "UppercaseProxy()")
Base.show(io::IO, ::UppercaseActor{L}) where L = print(io, "UppercaseActor($L)")
