export faulted

import Base: show

"""
    FaultedObservable{D, H}(err, scheduler::H)

Observable that emits no items to the Actor and just sends an error notification on subscription.

# Constructor arguments
- `err`: error to emit on subscription
- `scheduler`: scheduler-like object

See also: [`faulted`](@ref)
"""
struct FaultedObservable{D, E, H} <: Subscribable{D}
    err       :: E
    scheduler :: H
end

getscheduler(observable::FaultedObservable) = observable.scheduler

function on_subscribe!(observable::FaultedObservable, actor)
    error!(getscheduler(observable), actor, observable.err)
    return noopSubscription
end

"""
    faulted(err::E; scheduler::H = AsapScheduler())            where { E, H }
    faulted(::Type{T}, err::E; scheduler::H = AsapScheduler()) where { T, E, H }

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

See also: [`Subscribable`](@ref), [`logger`](@ref)
"""
function faulted end

faulted(::Type{T}; scheduler::H = AsapScheduler())         where { T, H }    = error("Missing error value in faulted() constructor.")
faulted(err::E; scheduler::H = AsapScheduler())            where { E, H }    = FaultedObservable{Any, E, H}(err, scheduler)
faulted(::Type{T}, err::E; scheduler::H = AsapScheduler()) where { T, E, H } = FaultedObservable{T, E, H}(err, scheduler)

Base.show(io::IO, ::FaultedObservable{D, E, H}) where { D, E, H } = print(io, "FaultedObservable($D, $E, $H)")
