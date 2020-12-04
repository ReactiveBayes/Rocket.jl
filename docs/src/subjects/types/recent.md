# [RecentSubject](@id subject_recent)

```@docs
RecentSubject
RecentSubjectFactory
```

## Description

One of the variants of Subjects is the `RecentSubject`, which has a notion of "the recent value". It stores the latest value emitted to its consumers, and whenever a new Observer subscribes, it will immediately receive the "recent value" from the `RecentSubject`.

!!! note
    RecentSubjects is a more efficient version of ReplaySubjects with replay size equal to one.

## Examples

In the following example, after `RecentSubject` is initialized the first Observer receives nothing when it subscribes. The second Observer receives the value 2 even though it subscribed after the value 2 was sent.

```julia
using Rocket

subject = RecentSubject(Int)

subscription1 = subscribe!(subject, logger("1"))

next!(subject, 1)
next!(subject, 2)

subscription2 = subscribe!(subject, logger("2"))

next!(subject, 3)

unsubscribe!(subscription1)
unsubscribe!(subscription2)

// Logs
// [1] Data: 1
// [1] Data: 2
// [2] Data: 2
// [1] Data: 3
// [2] Data: 3
```
