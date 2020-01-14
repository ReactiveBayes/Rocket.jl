# [Subscription](@id section_subscription)


A Subscription represents a disposable resource, usually the execution of an Observable. A Subscription has one important method: `unsubscribe!(t::T) where { T <: Teardown }`, which takes some teardown logic object as one argument and disposes the resource held by the subscription.

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

For more information about subscription and teardown logic see [API Section](@ref teardown_api)
