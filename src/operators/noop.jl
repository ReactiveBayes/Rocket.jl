export noop

import Base: show

"""
    noop()

Creates a noop operator, which does nothing, but breaks operator composition type inference checking procedure for Julia's compiler.
It might be useful for very long chain of operators, because Julia tries to statically infer data types at compile-time for the whole chain and
can run into StackOverflow issues.

```
using Rx

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
    return proxy(L, source, NoopProxy{L}())
end

struct NoopProxy{L} <: ActorProxy end

actor_proxy!(proxy::NoopProxy{L}, actor) where L = NoopActor{L}(actor)

struct NoopActor{L} <: Actor{L}
    actor
end

is_exhausted(actor::NoopActor) = is_exhausted(actor.actor)

on_next!(t::NoopActor{L}, data::L) where L = next!(t.actor, data)
on_error!(t::NoopActor, err)               = error!(t.actor, err)
on_complete!(t::NoopActor)                 = complete!(t.actor)

Base.show(io::IO, operator::NoopOperator)         = print(io, "NoopOperator()")
Base.show(io::IO, proxy::NoopProxy{L})    where L = print(io, "NoopProxy($L)")
Base.show(io::IO, actor::NoopActor{L})    where L = print(io, "NoopActor($L)")
