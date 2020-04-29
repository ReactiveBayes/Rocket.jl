# [Actors API](@id actors_api)

## How to create a custom Actor

At first custom actor should implement a custom method for the [`as_actor`](@ref) function.
Rocket.jl also provides a number of helper actor abstract types with predefined [`as_actor`](@ref) method behavior (see [Traits API section](@ref actors_api_traits)).

```julia
using Rocket

struct MyCustomActor end

as_actor(::Type{<:MyCustomActor}) = Rocket.BaseActorTrait{Int}()

```

or

```julia
using Rocket

struct MyCustomActor <: Actor{Int} end # Automatically specifies BaseActorTrait{Int} behavior.
```

Additionally custom actor must provide a custom methods for [`on_next!`](@ref), [`on_error!`](@ref) and/or [`on_complete!`](@ref) functions. Depending on specified actor trait behavior some methods may or may not be optional.

```julia
using Rocket

struct MyCustomActor <: Actor{Int} end

Rocket.on_next!(actor::MyCustomActor, data::Int)  = # custom logic here
Rocket.on_error!(actor::MyCustomActor, err)       = # custom logic here
Rocket.on_complete!(actor::MyCustomActor)         = # custom logic here
```

or

```julia
using Rocket

struct MyCustomCompletionActor <: CompletionActor{Int} end

Rocket.on_complete!(actor::MyCustomCompletionActor) = # custom logic here
```


## [Traits](@id actors_api_traits)

```@docs
ActorTrait
ValidActorTrait
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
