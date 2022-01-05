# [Actors](@id section_actors)

An __Actor__ is the most primitive unit of computation: it receives a message and performs a computation.

An actor is analogous to an object in an object-oriented languages. An object receives a message (a method call) and does something depending on which message it receives (the method we are calling). The main difference is that actors are completely isolated from each other, and they will never share memory. It’s also worth mentioning that an actor can maintain a private state that should never be changed directly by another actor.

For a quick introduction to Actor models, see [this article](https://www.brianstorti.com/the-actor-model/).

The API of Rocket.jl's Actors is similar to [RxJS](https://rxjs.dev/guide/overview) subscribers.

## First example

The following example implements an Actor that retains each received value from an Observable. First lets setup our environment by importing `Rocket.jl` package:

```@example actor_tutorial
using Rocket
```

We create a custom actor structure with custom logic
In our example our actor will simply keep all incoming data in an internal storage

```@example actor_tutorial
struct CustomKeepActor
    values :: Vector{Int} 
    CustomKeepActor() = new(Vector{Int}())
end
nothing #hide
```

The only one requirement for a custom actor is to implement [`on_next!`](@ref), [`on_error!`](@ref) and [`on_complete!`](@ref) methods. See also [API reference](@ref actors_api).

```@example actor_tutorial
Rocket.on_next!(actor::CustomKeepActor, data::Int) = push!(actor.values, data)
Rocket.on_error!(actor::CustomKeepActor, err)      = error(err)
Rocket.on_complete!(actor::CustomKeepActor)        = println("Completed!")
nothing #hide
```

```@example actor_tutorial
source       = from_iterable([ 1, 2, 3 ])
actor        = CustomKeepActor()
subscription = subscribe!(source, actor)
nothing #hide
```

We can verify that our actor indeed saved all incoming data in its internal storage:

```@example actor_tutorial
actor.values
```

It is also possible to use Julia's multiple dispatch feature and dispatch on type of the event

```@example actor_tutorial
struct MyCustomActor end

Rocket.on_next!(::MyCustomActor, data::Int)     = println("Int: $data")
Rocket.on_next!(::MyCustomActor, data::Float64) = println("Float64: $data")
Rocket.on_next!(::MyCustomActor, data)          = println("Something else: $data")

Rocket.on_error!(::MyCustomActor, err) = error(err)
Rocket.on_complete!(::MyCustomActor)   = begin end

nothing #hide
```

```@example actor_tutorial
source       = from_iterable([ 1, 1.0, "string" ])
actor        = MyCustomActor()
subscription = subscribe!(source, actor)
nothing #hide
```

## Lambda actor

For debugging purposes it may be convenient to work with the [`LambdaActor`](@ref). It provides an interface that defines callbacks for "next", "error" and "complete" events.

```@example actor_tutorial

source       = from_iterable([1, 2, 3])
subscription = subscribe!(source, lambda(
    on_next     = (d) -> println("Data received: ", d),
    on_error    = (e) -> error(e),
    on_complete = ()  -> println("Completed")
))
nothing #hide
```

## Function actor

Sometimes it is convenient to pass only `on_next` callback. Rocket.jl provides the [`FunctionActor`](@ref) which automatically converts any function object passed in the `subscribe!` function to a proper actor which listens only for data events, throws an exception on error event and ignores completion event.

```@example actor_tutorial
source       = from_iterable([1, 2, 3])
subscription = subscribe!(source, (d) -> println(d))
nothing #hide
```
