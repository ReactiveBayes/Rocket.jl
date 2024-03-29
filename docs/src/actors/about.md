# [Actors](@id section_actors)

An __Actor__ is the most primitive unit of computation: it receives a message and performs a computation.

An actor is analogous to an object in an object-oriented languages. An object receives a message (a method call) and does something depending on which message it receives (the method we are calling). The main difference is that actors are completely isolated from each other, and they will never share memory. It’s also worth mentioning that an actor can maintain a private state that should never be changed directly by another actor.

For a quick introduction to Actor models, see [this article](https://www.brianstorti.com/the-actor-model/).

The API of Rocket.jl's Actors is similar to [RxJS](https://rxjs.dev/guide/overview) subscribers.

## First example

The following example implements an Actor that retains each received value from an Observable.

```julia
using Rocket

struct CustomKeepActor <: Actor{Int}
    values::Vector{Int}

    CustomKeepActor() = new(Vector{Int}())
end

Rocket.on_next!(actor::CustomKeepActor, data::Int) = push!(actor.values, data)
Rocket.on_error!(actor::CustomKeepActor, err)      = error(err)
Rocket.on_complete!(actor::CustomKeepActor)        = println("Completed!")

source     = from([ 1, 2, 3 ])
keep_actor = CustomKeepActor()
subscribe!(source, keep_actor)

# Logs
# Completed!

println(keep_actor.values)

# Logs
# [1, 2, 3]
```

An actor may be not interested in the values itself, but merely the completion of an event. In this case, Rocket.jl provides a [`CompletionActor`](@ref) abstract type.
See also [`NextActor`](@ref) and [`ErrorActor`](@ref).

```julia
using Rocket

struct CompletionNotificationActor <: CompletionActor{Int} end

Rocket.on_complete!(::CompletionNotificationActor) = println("Completed!")

source = from([ 1, 2, 3 ])
subscribe!(source, CompletionNotificationActor());

# Logs
# Completed
```

It is also possible to use Julia's multiple dispatch feature and dispatch on type of the event

```julia
using Rocket

struct MyCustomActor <: NextActor{Any} end

Rocket.on_next!(::MyCustomActor, data::Int)     = println("Int: $data")
Rocket.on_next!(::MyCustomActor, data::Float64) = println("Float64: $data")
Rocket.on_next!(::MyCustomActor, data)          = println("Something else: $data")

source = from([ 1, 1.0, "string" ])
subscribe!(source, MyCustomActor());

# Logs
# Int: 1
# Float64: 1.0
# Something else: string

```

## Lambda actor

For debugging purposes it may be convenient to work with a [`LambdaActor`](@ref). This provides an interface that defines callbacks for "next", "error" and "complete" events.
But this generic actor does not allow to dispatch on the type of the event.

```julia
using Rocket

source = from([1, 2, 3])

subscribe!(source, lambda(
    on_next     = (d) -> println(d),
    on_error    = (e) -> error(e),
    on_complete = ()  -> println("Completed")
))

# Logs
# 1
# 2
# 3
# Completed
```

## Function actor

Sometimes it is convenient to pass only `on_next` callback. Rocket.jl provides a `FunctionActor` which automatically converts any function object passed in the `subscribe!` function to a proper actor which listens only for data events, throws an exception on error event and ignores completion message.

```julia
using Rocket

source = from([1, 2, 3])

subscribe!(source, (d) -> println(d))

# Logs
# 1
# 2
# 3
```
