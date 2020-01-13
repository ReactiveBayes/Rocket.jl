export lowercase
export LowercaseOperator, on_call!, operator_right
export LowercaseProxy, actor_proxy!
export LowercaseActor, on_next!, on_error!, on_complete!, is_exhausted

import Base: lowercase

"""
    lowercase()

Creates an lowercase operator, which forces each value to be in lower case

# Producing

Stream of type `<: Subscribable{L}` where L referes to type of data of input Observable

# Examples

```jldoctest
using Rx

source = of("Hello, world!")
subscribe!(source |> lowercase(), LoggerActor{String}())
;

# output

[LogActor] Data: hello, world!
[LogActor] Completed
```
"""
lowercase() = LowercaseOperator()

struct LowercaseOperator <: InferableOperator end

function on_call!(::Type{L}, ::Type{L}, operator::LowercaseOperator, source) where L
    return ProxyObservable{L}(source, LowercaseProxy{L}())
end

operator_right(::LowercaseOperator, ::Type{L}) where L = L

struct LowercaseProxy{L} <: ActorProxy end

actor_proxy!(proxy::LowercaseProxy{L}, actor) where L = LowercaseActor{L}(actor)

struct LowercaseActor{L} <: Actor{L}
    actor
end

is_exhausted(actor::LowercaseActor) = is_exhausted(actor.actor)

on_next!(actor::LowercaseActor{L}, data::L) where L = next!(actor.actor, lowercase(data))
on_error!(actor::LowercaseActor, err)       where L = error!(actor.actor, err)
on_complete!(actor::LowercaseActor)         where L = complete!(actor.actor)
