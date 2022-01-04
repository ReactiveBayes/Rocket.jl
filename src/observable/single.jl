export SingleObservable, of

import Base: show

"""
    SingleObservable{D, H}(value::D, scheduler::H)

SingleObservable wraps single value of type `D` into a observable.

# Constructor arguments
- `value`: a single value to emit
- `scheduler`: scheduler-like object

# See also: [`of`](@ref), [`Subscribable`](@ref)
"""
struct SingleObservable{D, H} <: Subscribable{D}
    value     :: D
    scheduler :: H
end

getrecent(observable::SingleObservable)    = observable.value
getscheduler(observable::SingleObservable) = observable.scheduler

function on_subscribe!(observable::SingleObservable, actor)
    scheduler = getscheduler(observable)
    next!(scheduler, actor, observable.value)
    complete!(scheduler, actor)
    return noopSubscription
end

"""
    of(value, scheduler::H = AsapScheduler()) where { H }

Creation operator for the `SingleObservable` that emits a single value x and then completes.

# Arguments
- `x`: value to be emmited before completion
- `scheduler`: optional, scheduler-like object

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
of(value::T, scheduler::H = AsapScheduler()) where { T, H } = SingleObservable{T, H}(value, scheduler)

Base.show(io::IO, ::SingleObservable{D, H}) where { D, H } = print(io, "SingleObservable($D, $H)")
