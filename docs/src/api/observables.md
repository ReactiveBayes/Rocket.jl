# [Observables API](@id observables_api)

Any observable-like should implement a valid subscribable logic.

## Traits

```@docs
SubscribableTrait
as_subscribable
ValidSubscribable
InvalidSubscribable
```

## Types

```@docs
Subscribable
subscribe!
on_subscribe!
```

## Errors

```@docs
InvalidSubscribableTraitUsageError
InconsistentActorWithSubscribableDataTypesError
MissingOnSubscribeImplementationError
```
