# [ReplaySubject](@id subject_replay)

```@docs
make_replay_subject
```

```@docs
ReplaySubject
```

## Description

A `ReplaySubject` is similar to a `BehaviorSubject` in that it can send old values to new subscribers, but it can also record a part of the Observable execution.

!!! note
    A ReplaySubject records multiple values from the Observable execution and replays them to new subscribers.

## Examples

When creating a `ReplaySubject`, you can specify how many values to replay:

```julia
using Rocket

subject = make_replay_subject(Int, 3) # buffer 3 values for new subscribers

subscription1 = subscribe!(subject, logger("1"))

next!(subject, 1)
next!(subject, 2)
next!(subject, 3)
next!(subject, 4)

subscription2 = subscribe!(subject, logger("2"))

next!(subject, 5)

unsubscribe!(subscription1)
unsubscribe!(subscription2)

// Logs
// [1] Data: 1
// [1] Data: 2
// [1] Data: 3
// [1] Data: 4
// [2] Data: 2
// [2] Data: 3
// [2] Data: 4
// [1] Data: 5
// [2] Data: 5
```
