export uppercase
export UppercaseOperator, on_call!, operator_right
export UppercaseProxy, actor_proxy!
export on_next!, on_error!, on_complete!

import Base: uppercase

"""
    uppercase()

Creates an uppercase operator, which forces each value to be in upper case

# Producing

Stream of type `<: Subscribable{L}` where L referes to type of data of input Observable

# Examples

```jldoctest
using Rx

source = of("Hello, world!")
subscribe!(source |> uppercase(), LoggerActor{String}())
;

# output

[LogActor] Data: HELLO, WORLD!
[LogActor] Completed
```
"""
uppercase() = UppercaseOperator()

struct UppercaseOperator <: InferableOperator end

function on_call!(::Type{L}, ::Type{L}, operator::UppercaseOperator, source) where L
    return ProxyObservable{L}(source, UppercaseProxy{L}())
end

operator_right(::UppercaseOperator, ::Type{L}) where L = L

struct UppercaseProxy{L} <: ActorProxy end

actor_proxy!(proxy::UppercaseProxy{L}, actor::A) where { A <: AbstractActor{L} } where L = UppercaseActor{L, A}(actor)

struct UppercaseActor{ L, A <: AbstractActor{L} } <: Actor{L}
    actor :: A
end

on_next!(actor::UppercaseActor{L, A}, data::L) where { A <: AbstractActor{L} } where L = next!(actor.actor, uppercase(data))
on_error!(actor::UppercaseActor{L, A}, err) where { A <: AbstractActor{L} } where L    = error!(actor.actor, err)
on_complete!(actor::UppercaseActor{L, A})  where { A <: AbstractActor{L} } where L     = complete!(actor.actor)
