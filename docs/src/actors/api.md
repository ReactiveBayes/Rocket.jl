# [Actors API](@id actors_api)

## Actor traits


```@docs
ActorTrait
as_actor
BaseActorTrait
NextActorTrait
ErrorActorTrait
CompletionActorTrait
InvalidActorTrait
```

## Actor types

```@docs
AbstractActor
Actor
NextActor
ErrorActor
CompletionActor
```

## Actor events

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

## Actor errors

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
