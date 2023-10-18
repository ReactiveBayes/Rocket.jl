# [Subscription](@id section_subscription)


A __Subscription__ represents a disposable resource, usually the execution of an Observable. A Subscription has one important method: `unsubscribe!(teardown)`, which takes some teardown logic object as one argument and disposes the resource held by the subscription.

```julia
using Rocket

source = Subject(Int)

next!(source, 0) # Logs nothing as there is no subscribers

subscription = subscribe!(source, logger())

next!(source, 1) # Logs [LogActor] Data: 1 into standard output

unsubscribe!(subscription)

next!(source, 2) # Logs nothing as a single one actor has unsubscribed
```

!!! note
    A Subscription essentially just has its own specific method for `unsubscribe!()` function which releases resources or cancel Observable executions. Any Observable has to return a valid `Teardown` object.


The `unsubscribe!` function also supports multiple unsubscriptions at once. If the input argument to the `unsubscribe!` function is either a tuple or a vector, it will first check that all of the arguments are valid subscription objects and if this is true it will unsubscribe from each of them individually.

```julia

source = Subject(Int)

subscription1 = subscribe!(source, logger())
subscription2 = subscribe!(source, logger())

unsubscribe!((subscription1, subscription2))

# or similarly
# unsubscribe!([ subscription1, subscription2 ])

```

For more information about subscription and teardown logic see the [API Section](@ref teardown_api)
