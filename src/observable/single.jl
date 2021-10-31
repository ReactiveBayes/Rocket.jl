export SingleObservable, of

import Base: ==
import Base: show

"""
    SingleObservable{D, H}(value::D, scheduler::H)

SingleObservable wraps single value of type `D` into a observable.

# Constructor arguments
- `value`: a single value to emit
- `scheduler`: scheduler-like object

# See also: [`of`](@ref), [`Subscribable`](@ref)
"""
@subscribable struct SingleObservable{D, H} <: ScheduledSubscribable{D}
    value     :: D
    scheduler :: H
end

getrecent(observable::SingleObservable) = observable.value
getscheduler(observable::SingleObservable) = observable.scheduler

function on_subscribe!(observable::SingleObservable, actor, scheduler)
    next!(actor, observable.value, scheduler)
    complete!(actor, scheduler)
    return voidTeardown
end

"""
    of(x; scheduler::H = AsapScheduler()) where { H <: AbstractScheduler }

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
of(x::T; scheduler::H = AsapScheduler()) where { T, H <: AbstractScheduler } = SingleObservable{T, H}(x, scheduler)

Base.:(==)(left::SingleObservable{D, H},  right::SingleObservable{D, H}) where { D, H } = left.value == right.value
Base.:(==)(left::SingleObservable,        right::SingleObservable)                      = false

Base.show(io::IO, ::SingleObservable{D, H}) where { D, H } = print(io, "SingleObservable($D, $H)")
