export CompletedObservable, completed

import Base: ==
import Base: show

"""
    CompletedObservable{D, H}(scheduler::H)

Observable that emits no items to the Actor and just sends a complete notification on subscription.

# Constructor arguments
- `scheduler`: Scheduler-like object

See also: [`Subscribable`](@ref), [`completed`](@ref)
"""
struct CompletedObservable{D, H} <: ScheduledSubscribable{D}
    scheduler :: H
end

getscheduler(observable::CompletedObservable) = observable.scheduler

function on_subscribe!(observable::CompletedObservable, actor, scheduler)
    complete!(actor, scheduler)
    return voidTeardown
end

"""
    completed(::Type{T} = Any; scheduler::H = AsapScheduler()) where { T, H <: AbstractScheduler }

Creation operator for the `CompletedObservable` that emits no items to the Actor and immediately sends a complete notification on subscription.

# Arguments
- `T`: type of output data source, optional, `Any` is the default
- `scheduler`: optional, scheduler-like object

# Examples

```jldoctest
using Rocket

source = completed(Int)
subscribe!(source, logger())
;

# output

[LogActor] Completed

```

See also: [`CompletedObservable`](@ref), [`subscribe!`](@ref), [`logger`](@ref)
"""
completed(::Type{T} = Any; scheduler::H = AsapScheduler()) where { T, H <: AbstractScheduler } = CompletedObservable{T, H}(scheduler)

Base.:(==)(::CompletedObservable{T, H}, ::CompletedObservable{T, H}) where { T, H } = true
Base.:(==)(::CompletedObservable,       ::CompletedObservable)                      = false

Base.show(io::IO, ::CompletedObservable{T, H}) where { T, H } = print(io, "CompletedObservable($T, $H)")
