export interval

"""
    interval(period::Union{Int, Nothing} = nothing)

Creation operator for the `TimerObservable`. `interval` returns an Observable that emits an infinite sequence of ascending integers,
with a constant interval of time of your choosing between those emissions.
The first emission is not sent immediately, but only after the first period has passed.

# Arguments
- `interval`: the interval size in milliseconds

# Examples

```
using Rocket

source = interval(50)   # emits 0, 1, 2, ... every 50 ms

subscription = subscribe!(source, logger())
sleep(0.215)            # ~4 emissions: 0, 1, 2, 3
unsubscribe!(subscription)

# Each subscription gets its own independent timer and counter, so re-subscribing
# restarts the count from 0 (the counter does not survive an `unsubscribe!`).
subscription = subscribe!(source, logger())
sleep(0.115)            # ~2 emissions: 0, 1
unsubscribe!(subscription)
;

# output

[LogActor] Data: 0
[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Data: 3
[LogActor] Data: 0
[LogActor] Data: 1
```

See also: [`timer`](@ref), [`TimerObservable`](@ref), [`Subscribable`](@ref)
"""
interval(period::Real) = timer(period, period)
