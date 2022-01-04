export from_iterable

import Base: show

"""
    from_iterable(iterator, scheduler::H = AsapScheduler()) where { H }

Creation operator for the `IterableObservable` that wraps given iterator into an observable object.

# Arguments
- `iterator`: an iterator object to be wrapped an observable
- `scheduler`: optional, scheduler-like object

# Note
`iterable` operators does not create a copy of iterator.
Any changes in the `iterator` object might be visible in the created observable.
In addition, if iterator is state-full subsequent `subscribe!` functions may deliver different results.
For side-effects free behavior consider using `from_iterable(collect(iterator))`.

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

See also: [`Subscribable`](@ref), [`subscribe!`](@ref), [`from_iterable`](@ref)
"""
from_iterable(iterator::I, scheduler::H = AsapScheduler()) where { I, H } = IterableObservable{eltype(I), I, H}(iterator, scheduler)

struct IterableObservable{D, I, H} <: Subscribable{D}
    iterator  :: I
    scheduler :: H
end

getscheduler(observable::IterableObservable) = observable.scheduler

function on_subscribe!(observable::IterableObservable, actor)
    scheduler = getscheduler(observable)
    state     = iterate(observable.iterator)
    while state !== nothing
        next!(scheduler, actor, state[1])
        state = iterate(observable.iterator, state[2])
    end
    complete!(scheduler, actor)
    return noopSubscription
end

Base.show(io::IO, ::IterableObservable{D, H}) where { D, H } = print(io, "IterableObservable($D, $H)")
