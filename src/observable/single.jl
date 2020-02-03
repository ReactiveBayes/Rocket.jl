export SingleObservable, of

import Base: ==

"""
    SingleObservable{D}(value::D)

SingleObservable wraps single value of type `D` into a synchronous observable

# See also: [`of`](@ref), [`Subscribable`](@ref)
"""
struct SingleObservable{D} <: Subscribable{D}
    value :: D
end

function on_subscribe!(observable::SingleObservable, actor)
    next!(actor, observable.value)
    complete!(actor)
    return VoidTeardown()
end

"""
    of(x)

Creation operator for the `SingleObservable` that emits a single value x and then completes.

# Arguments
- `x`: value to be emmited before completion

# Examples

```jldoctest
using Rocket

source = of(1)
subscribe!(source, logger())
;

# output

[LogActor] Data: 1
[LogActor] Completed

```

See also: [`SingleObservable`](@ref), [`subscribe!`](@ref), [`logger`](@ref)
"""
of(x::T) where T = SingleObservable{T}(x)

Base.:(==)(left::SingleObservable{D},  right::SingleObservable{D})  where D           = left.value == right.value
Base.:(==)(left::SingleObservable{D1}, right::SingleObservable{D2}) where D1 where D2 = false
