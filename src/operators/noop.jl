export noop

import Base: show

"""
    noop()

Creates a noop operator, which does nothing, but breaks operator composition type inference checking procedure for Julia's compiler.
It might be useful for very long chain of operators, because Julia tries to statically infer data types at compile-time for the whole chain and
can run into StackOverflow issues.

```
using Rocket

source = from(1:5)

for i in 1:1000
    source = source |> map(Int, d -> d + 1) |> noop()
end

subscribe!(source, logger())
;

# output

[LogActor] Data: 1001
[LogActor] Data: 1002
[LogActor] Data: 1003
[LogActor] Data: 1004
[LogActor] Data: 1005
[LogActor] Completed
```

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`logger`](@ref), [`map`](@ref)
"""
noop() = NoopOperator()

struct NoopOperator <: InferableOperator end

operator_right(operator::NoopOperator, ::Type{L}) where L = L

function on_call!(::Type{L}, ::Type{L}, operator::NoopOperator, source) where L
    return proxy(L, source, NoopProxy())
end

struct NoopProxy <: ActorSourceProxy end

actor_proxy!(::Type{L}, proxy::NoopProxy, actor)   where L = NoopActor{L}(actor)
source_proxy!(::Type{L}, proxy::NoopProxy, source) where L = NoopSource{L}(source)

struct NoopActor{L} <: Actor{L}
    actor
end

on_next!(actor::NoopActor{L}, data::L) where L = next!(actor.actor, data)
on_error!(actor::NoopActor, err)               = error!(actor.actor, err)
on_complete!(actor::NoopActor)                 = complete!(actor.actor)

struct NoopSource{L} <: Subscribable{L}
    source
end

function on_subscribe!(source::NoopSource, actor)
    return subscribe!(source.source, actor)
end

Base.show(io::IO, ::NoopOperator)          = print(io, "NoopOperator()")
Base.show(io::IO, ::NoopProxy)             = print(io, "NoopProxy()")
Base.show(io::IO, ::NoopActor{L})  where L = print(io, "NoopActor($L)")
Base.show(io::IO, ::NoopSource{L}) where L = print(io, "NoopSource($L)")
