export CompletedObservable, on_subscribe!, completed

"""
    CompletedObservable{D}()

Observable that emits no items to the Actor and immediately emits a complete notification on subscription.

See also: [`completed`](@ref)
"""
struct CompletedObservable{D} <: Subscribable{D} end

function on_subscribe!(observable::CompletedObservable{D}, actor::A) where { A <: AbstractActor{D} } where D
    complete!(actor)
    return VoidTeardown()
end

"""
    completed(T = Any)

Creates an Observable that emits no items to the Actor and immediately emits a complete notification.

# Arguments
- `T`: type of output data source, optional, `Any` is the default

# Examples

```jldoctest
using Rx

source = completed(Int)
subscribe!(source, LoggerActor{Int}())
;

# output

[LogActor] Completed

```

See also: [`CompletedObservable`](@ref)
"""
completed(T = Any) = CompletedObservable{T}()
