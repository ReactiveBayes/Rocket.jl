export iterable

import Base: show

"""
    iterable(iterator; scheduler::H = AsapScheduler()) where { H <: AbstractScheduler }

Creation operator for the `IterableObservable` that wraps given iterator into an observable object.

# Arguments
- `iterator`: an iterator object to be wrapped an observable
- `scheduler`: optional, scheduler-like object

# Note
`iterable` operators does not create a copy of iterator.
Any changes in the `iterator` object might be visible in the created observable.
For side-effects free behavior consider using `from` creation operator which creates a copy of a given object
with a `collect` function.

# Examples

```jldoctest
using Rocket

source = iterable([ 0, 1, 2 ])
subscribe!(source, logger())
;

# output

[LogActor] Data: 0
[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Completed
```

```jldoctest
using Rocket

source = iterable("Hello")
subscribe!(source, logger())
;

# output

[LogActor] Data: H
[LogActor] Data: e
[LogActor] Data: l
[LogActor] Data: l
[LogActor] Data: o
[LogActor] Completed
```

See also: [`ScheduledSubscribable`](@ref), [`subscribe!`](@ref), [`from`](@ref)
"""
function iterable(iterator::I; scheduler::H = AsapScheduler()) where { I, H <: AbstractScheduler }
    return IterableObservable{eltype(I), I, H}(iterator, scheduler)
end

struct IterableObservable{D, I, H} <: ScheduledSubscribable{D}
    iterator  :: I
    scheduler :: H
end

getscheduler(observable::IterableObservable) = observable.scheduler

function on_subscribe!(observable::IterableObservable, actor, scheduler)
    state = iterate(observable.iterator)
    while state !== nothing
        next!(actor, state[1], scheduler)
        state = iterate(observable.iterator, state[2])
    end
    complete!(actor, scheduler)
    return voidTeardown
end

Base.show(io::IO, ::IterableObservable{D, I, H}) where { D, I, H } = print(io, "IterableObservable($D, $I, $H)")
