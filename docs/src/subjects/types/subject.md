# [Subject](@id subject)

```@docs
Subject
SubjectFactory
```

## Description

Every Subject is an Observable. Given a Subject, you can subscribe to it, providing an Actor, which will start receiving values normally. From the perspective of the Observer, it cannot tell whether the Observable execution is coming from a plain unicast Observable or a Subject.

Internally to the Subject, subscribe does not invoke a new execution that delivers values. It simply registers the given Observer in a list of Observers.

Every Subject is an Actor. It is an object with the methods `next!`, `error!`, and `complete!`. To feed a new value to the Subject, just call `next!(subject, theValue)`, and it will be multicasted to the Actors registered to listen to the Subject.

!!! note
    By convention, every actor subscribed to a Subject observable is not allowed to throw exceptions during `next!`, `error!` and `complete!` calls. 
    Doing so would lead to undefined behaviour. Use `safe()` operator to bypass this rule. 

## Examples

In the following example, the `BehaviorSubject` is initialized with the value 0 which the first Observer receives when it subscribes. The second Observer receives the value 2 even though it subscribed after the value 2 was sent.

```julia
using Rocket

subject = Subject(Int)

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
// [1] Data: 3
// [2] Data: 3
```
