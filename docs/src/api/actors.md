# [Actors API](@id actors_api)

## Traits

```@docs
ActorTrait
as_actor
BaseActorTrait
NextActorTrait
ErrorActorTrait
CompletionActorTrait
InvalidActorTrait
```

## Types

```@docs
AbstractActor
Actor
NextActor
ErrorActor
CompletionActor
```

## Events

```@docs
next!
error!
complete!
is_exhausted
```

```@docs
on_next!
on_error!
on_complete!
```

## Factory

```@docs
AbstractActorFactory
create_actor
MissingCreateActorFactoryImplementationError
```

## Errors

```@docs
InvalidActorTraitUsageError
InconsistentSourceActorDataTypesError
MissingDataArgumentInNextCall
MissingErrorArgumentInErrorCall
ExtraArgumentInCompleteCall
MissingOnNextImplementationError
MissingOnErrorImplementationError
MissingOnCompleteImplementationError
```
