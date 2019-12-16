# Subscription

What is a Subscription? A Subscription is an object that represents a disposable resource, usually the execution of an Observable. A Subscription has one important method, `unsubscribe!(t::T) where { T <: Teardown }`, that takes some teardown logic object as one argument and just disposes the resource held by the subscription.

```julia
source = Subject{Int}()

next!(source, 0) # Logs nothing as there is no subscribers

subscription = subscribe!(source, LoggerActor{Int}())

next!(source, 1) # Logs [LogActor] Data: 1 into standart output

unsubscribe!(subscription)

next!(source, 2) # Logs nothing as a single one actor has unsubscribed
```

!!! note
    A Subscription essentially just has an `unsubscribe!()` function to release resources or cancel Observable executions. Any Observable has to return a `Teardown` object which represents a supertype of any Subscription.
