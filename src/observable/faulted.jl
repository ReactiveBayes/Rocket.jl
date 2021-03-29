export FaultedObservable, faulted

import Base: ==
import Base: show

"""
    FaultedObservable{D, H}(err, scheduler::H)

Observable that emits no items to the Actor and just sends an error notification on subscription.

# Constructor arguments
- `err`: error to emit on subscription
- `scheduler`: scheduler-like object

See also: [`faulted`](@ref)
"""
@subscribable struct FaultedObservable{D, H} <: ScheduledSubscribable{D}
    err
    scheduler :: H
end

getscheduler(observable::FaultedObservable) = observable.scheduler

function on_subscribe!(observable::FaultedObservable, actor, scheduler)
    error!(actor, observable.err, scheduler)
    return voidTeardown
end

"""
    faulted(err; scheduler::H = AsapScheduler())            where { H <: AbstractScheduler }
    faulted(::Type{T}, err; scheduler::H = AsapScheduler()) where { T, H <: AbstractScheduler }

Creation operator for the `FaultedObservable` that emits no items to the Actor and immediately sends an error notification.

# Arguments
- `err`: the particular Error to pass to the error notification.
- `T`: type of output data source, optional, `Any` by default
- `scheduler`: optional, scheduler-like object

# Examples

```jldoctest
using Rocket

source = faulted("Error!")
subscribe!(source, logger())
;

# output

[LogActor] Error: Error!

```

See also: [`FaultedObservable`](@ref), [`subscribe!`](@ref)
"""
function faulted end

faulted(::Type{T}; scheduler::H = AsapScheduler())      where { T, H <: AbstractScheduler } = error("Missing error value in faulted() constructor.")
faulted(err; scheduler::H = AsapScheduler())            where { H <: AbstractScheduler }    = FaultedObservable{Any, H}(err, scheduler)
faulted(::Type{T}, err; scheduler::H = AsapScheduler()) where { T, H <: AbstractScheduler } = FaultedObservable{T, H}(err, scheduler)

Base.:(==)(e1::FaultedObservable{D, H},  e2::FaultedObservable{D, H}) where { D, H } = e1.err == e2.err
Base.:(==)(e1::FaultedObservable,     e2::FaultedObservable)                         = false

Base.show(io::IO, ::FaultedObservable{D, H}) where { D, H } = print(io, "FaultedObservable($D, $H)")

@deprecate throwError(T)    faulted(T)
@deprecate throwError(T, e) faulted(T, e)
