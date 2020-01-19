# [Subscription](@id section_subscription)


A __Subscription__ represents a disposable resource, usually the execution of an Observable. A Subscription has one important method: `unsubscribe!(teardown)`, which takes some teardown logic object as one argument and disposes the resource held by the subscription.

```julia
using Rx

source = subject(Int)

next!(source, 0) # Logs nothing as there is no subscribers

subscription = subscribe!(source, logger())

next!(source, 1) # Logs [LogActor] Data: 1 into standard output

unsubscribe!(subscription)

next!(source, 2) # Logs nothing as a single one actor has unsubscribed
```

!!! note
    A Subscription essentially just has its own specific method for `unsubscribe!()` function which releases resources or cancel Observable executions. Any Observable has to return a valid `Teardown` object.

For more information about subscription and teardown logic see the [API Section](@ref teardown_api)
