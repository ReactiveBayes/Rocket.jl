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

See also: [`Actor`](@ref), [`noop`](@ref)
"""
struct NoopActor <: Actor{Any} end

next!(::NoopActor, data) = begin end
error!(::NoopActor, err) = begin end
complete!(::NoopActor)   = begin end

"""
    noopActor 

An instance of `NoopActor` singleton object.

See also: [`NoopActor`]
"""
const noopActor = NoopActor()

noop() = noopActor
