# [BehaviorSubject](@id subject_behavior)

```@docs
make_behavior_subject
```

```@docs
BehaviorSubject
```

## Description

One of the variants of Subjects is the `BehaviorSubject`, which has a notion of "the current value". It stores the latest value emitted to its consumers, and whenever a new Observer subscribes, it will immediately receive the "current value" from the `BehaviorSubject`.

!!! note
    BehaviorSubjects are useful for representing "values over time". For instance, an event stream of birthdays is a Subject, but the stream of a person's age would be a BehaviorSubject.

## Examples

In the following example, the `BehaviorSubject` is initialized with the value 0 which the first Observer receives when it subscribes. The second Observer receives the value 2 even though it subscribed after the value 2 was sent.

```julia
using Rx

subject = make_behavior_subject(Int, 0)

subscription1 = subscribe!(subject, logger("1"))

next!(subject, 1)
next!(subject, 2)

subscription2 = subscribe!(subject, logger("2"))

next!(subject, 3)

unsubscribe!(subscription1)
unsubscribe!(subscription2)

// Logs
// [1] Data: 0
// [1] Data: 1
// [1] Data: 2
// [2] Data: 2
// [1] Data: 3
// [2] Data: 3
```
