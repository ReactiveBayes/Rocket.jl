# [Observables API](@id observables_api)

Any observable-like should implement a valid subscribable logic.

## Traits

```@docs
as_subscribable
SubscribableTrait
ValidSubscribableTrait
SimpleSubscribableTrait
ScheduledSubscribableTrait
InvalidSubscribable
```

## Types

```@docs
AbstractSubscribable
Subscribable
ScheduledSubscribable
subscribe!
on_subscribe!
```

## Errors

```@docs
InvalidSubscribableTraitUsageError
InconsistentActorWithSubscribableDataTypesError
MissingOnSubscribeImplementationError
MissingOnScheduledSubscribeImplementationError
```
