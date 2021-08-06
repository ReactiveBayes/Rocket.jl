# [Teardown API](@id teardown_api)

Any subscription-like object should implement a valid teardown logic.

## Example

```julia
using Rocket

struct MuCustomSubscription <: Teardown
    # some fields here
end

Rocket.as_teardown(::Type{<:MuCustomSubscription}) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::MyCustomSubscription)
    # dispose resources here
end
```

## Traits

```@docs
TeardownLogic
as_teardown
UnsubscribableTeardownLogic
on_unsubscribe!
CallableTeardownLogic
VoidTeardownLogic
InvalidTeardownLogic
```

## Types

```@docs
Teardown
unsubscribe!
```

## Errors

```@docs
InvalidTeardownLogicTraitUsageError
InvalidMultipleTeardownLogicTraitUsageError
MissingOnUnsubscribeImplementationError
```
