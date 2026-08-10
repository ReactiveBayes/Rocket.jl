export generate

import Base: show

"""
    generate(initial::D, condition::C, iterator::I; scheduler::H = AsapScheduler()) where { D, C, I, H <: AbstractScheduler }

Generates an observable sequence by running a state-driven loop producing the sequence's elements, using the specified scheduler to send out observer messages.

# Arguments
- `initial`: initial state
- `condition`: condition to terminate generation (upon returning false)
- `iterator`: iteration step function
- `scheduler`: optional, scheduler-like object

# Note
`iterator` object should return objects of the same type as `initial`.

!!! note
    `condition` must eventually return `false`. Generation runs synchronously while
    subscribing under the default `AsapScheduler`, so `subscribe!` does not return until the
    loop terminates; a `condition` that never returns `false` blocks indefinitely and cannot
    be unsubscribed. Use [`timer`](@ref)/[`interval`](@ref) for genuinely infinite streams.

# Examples

```jldoctest
using Rocket

source = generate(1, x -> x < 3, x -> x + 1)
subscribe!(source, logger())
;

# output
[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Completed
```

See also: [`ScheduledSubscribable`](@ref), [`subscribe!`](@ref)
"""
function generate(
    initial::D,
    condition::C,
    iterator::I;
    scheduler::H = AsapScheduler(),
) where {D,C,I,H<:AbstractScheduler}
    return GenerateObservable{D,C,I,H}(initial, condition, iterator, scheduler)
end

@subscribable struct GenerateObservable{D,C,I,H} <: ScheduledSubscribable{D}
    initial::D
    condition::C
    iterator::I
    scheduler::H
end

getscheduler(observable::GenerateObservable) = observable.scheduler

function on_subscribe!(observable::GenerateObservable, actor, scheduler)
    value = observable.initial
    while observable.condition(value)
        next!(actor, value, scheduler)
        value = observable.iterator(value)
    end
    complete!(actor, scheduler)
    return voidTeardown
end

Base.show(io::IO, observable::GenerateObservable{D}) where {D} =
    print(io, "GenerateObservable($D)")
