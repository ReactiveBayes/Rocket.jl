export noopActor, NoopActor

"""
    NoopActor{D}() where D

`NoopActor` does nothing with input data, error and complete events, can be useful for debugging (e.g. to start side-effects with [`tap`](@ref) operator)

# Examples

```jldoctest
using Rocket

source = from_iterable([ 0, 1, 2 ])
actor  = NoopActor()

subscribe!(source, actor)
;

# output

```

See also: [`noopActor`](@ref), [`tap`](@ref)
"""
struct NoopActor end

on_next!(::NoopActor, data) = begin end
on_error!(::NoopActor, err) = begin end
on_complete!(::NoopActor)   = begin end

"""
    noopActor 

An instance of the `NoopActor` singleton object.

# Examples

```jldoctest
using Rocket

source = from_iterable([ 0, 1, 2 ])
subscribe!(source, noopActor)

# output

```

See also: [`NoopActor`](@ref)
"""
const noopActor = NoopActor()
