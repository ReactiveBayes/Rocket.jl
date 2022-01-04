export NoopActor, noopActor

"""
    NoopActor{D}() where D

Void actor does nothing with input data, error and complete events, can be useful for debugging (e.g. to start side-effects with [`tap`](@ref) operator)

# Examples

```jldoctest
using Rocket

source = from([ 0, 1, 2 ])
actor  = NoopActor()

subscribe!(source, actor)
;

# output

```

See also: [`noop`](@ref)
"""
struct NoopActor end

on_next!(::NoopActor, data) = begin end
on_error!(::NoopActor, err) = begin end
on_complete!(::NoopActor)   = begin end

"""
    noopActor 

An instance of `NoopActor` singleton object.

See also: [`NoopActor`]
"""
const noopActor = NoopActor()

noop() = noopActor
