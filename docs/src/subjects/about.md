# [About subjects](@id section_subjects)

An Rocket.jl Subject is a special type of Observable that allows values to be multicasted to many Actors. While plain Observables are unicast (each subscribed Actor owns an independent execution of the Observable), Subjects are multicast.

!!! note
    A Subject is like an Observable, but can multicast to many Actors. Subjects are like event emitters: they maintain a registry of many listeners.


Every Subject is an Observable. Given a Subject, you can subscribe to it, providing an Actor, which will start receiving values normally. From the perspective of the Actor, it cannot tell whether the Observable execution is coming from a plain unicast Observable or a Subject.

Internally to the Subject, subscribe does not invoke a new execution that delivers values. Instead, it simply registers the given Actor in a list of Actors.

Every Subject is an Actor itself. It is an object with the methods `next!`, `error!`, and `complete!`. Call `next!(subject, theValue)` to feed a new value to the Subject, and it will be multicasted to the Actors that listen to the Subject.

In the example below, we have two Observers attached to a Subject, and we feed some values to the Subject:

```julia
using Rocket

source = Subject(Int)

subscription1 = subscribe!(source, lambda(
    on_next = (d) -> println("Actor 1: $d")
))

subscription2 = subscribe!(source, lambda(
    on_next = (d) -> println("Actor 2: $d")
))

next!(source, 0)

# Logs
# Actor 1: 0
# Actor 2: 0

unsubscribe!(subscription1)
unsubscribe!(subscription2)

```

Since a Subject is an actor, this also means you may provide a Subject as the argument to the subscribe of any Observable:

```julia
using Rocket

source = Subject(Int)

subscription1 = subscribe!(source, lambda(
    on_next = (d) -> println("Actor 1: $d")
))

subscription2 = subscribe!(source, lambda(
    on_next = (d) -> println("Actor 2: $d")
))

other_source = from([ 1, 2, 3 ])
subscribe!(other_source, source);

# Logs
# Actor 1: 1
# Actor 2: 1
# Actor 1: 2
# Actor 2: 2
# Actor 1: 3
# Actor 2: 3
```

Here, we essentially convert a unicast Observable execution to multicast, through the Subject. This demonstrates how Subjects offer a unique way to share Observable execution with multiple Observers.

## Schedulers

Subject (and many other observables) uses scheduler objects to schedule message delivery to their listeners.

## Synchronous scheduler

An `AsapScheduler` is similar to a [`Rocket.AsyncScheduler`](@ref). Both allows for Subject to scheduler their messages for multiple listeners,
but a `AsapScheduler` delivers all messages synchronously. `AsapScheduler` is a default scheduler for all `Subject` objects.

```@docs
Rocket.AsapScheduler
```

```julia
using Rocket

subject = Subject(Int, scheduler = Rocket.AsapScheduler())

subscription1 = subscribe!(subject, logger("Actor 1"))

println("Before next")
next!(subject, 1)
next!(subject, 2)
println("After next")

subscription2 = subscribe!(subject, logger("Actor 2"))

next!(subject, 3)

# Logs
# Before next
# [Actor 1] Data: 1
# [Actor 1] Data: 2
# After next
# [Actor 1] Data: 3
# [Actor 2] Data: 3
```

## Asynchronous Scheduler

One of the variants of schedulers is the `AsyncScheduler`, which delivers every message asynchronously (but still ordered) using a Julia's built-in `Task` object.

```@docs
Rocket.AsyncScheduler
```

```julia
using Rocket

subject = Subject(Int, scheduler = Rocket.AsyncScheduler())

subscription1 = subscribe!(subject, logger("Actor 1"))

println("Before next")
next!(subject, 1)
next!(subject, 2)
println("After next")

subscription2 = subscribe!(subject, logger("Actor 2"))

next!(subject, 3)

# Logs
# Before next
# After next
# [Actor 1] Data: 1
# [Actor 1] Data: 2
# [Actor 1] Data: 3
# [Actor 2] Data: 3

```

## Subject creation

```@docs
Subject
SubjectFactory
```
