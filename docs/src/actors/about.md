# [Actors](@id section_actors)

An __Actor__ is the most primitive unit of computation: it receives a message and performs a computation.

An actor is analogous to an object in an object-oriented languages. An object receives a message (a method call) and does something depending on which message it receives (the method we are calling). The main difference is that actors are completely isolated from each other, and they will never share memory. It’s also worth mentioning that an actor can maintain a private state that can never be changed directly by another actor.

For a quick introduction to Actor models, see [this article](https://www.brianstorti.com/the-actor-model/).

The API of Rx.jl's Actors is similar to [RxJS](https://rxjs.dev/guide/overview) subscribers.

## First example

The following example implements an Actor that retains each received value from an Observable.

```julia
using Rx

struct KeepActor <: Actor{Int}
    values::Vector{Int}

    KeepActor() = new(Vector{Int}())
end

Rx.on_next!(actor::KeepActor, data::Int) = push!(actor.values, data)
Rx.on_error!(actor::KeepActor, err)      = error(err)
Rx.on_complete!(actor::KeepActor)        = println("Completed!")

source     = from([ 1, 2, 3 ])
keep_actor = KeepActor()
subscribe!(source, keep_actor)

# Logs
# Completed!

println(keep_actor.values)

# Logs
# [1, 2, 3]
```

An actor may be not interested in the values itself, but merely the completion of an event. In this case, Rx.jl provides a [`CompletionActor`](@ref) abstract type.

```julia
using Rx

struct CompletionNotificationActor <: CompletionActor{Int} end

Rx.on_complete!(::CompletionNotificationActor) = println("Completed!")

source     = from([ 1, 2, 3 ])
subscribe!(source, CompletionNotificationActor());

# Logs
# Completed
```

## Lambda actor

For debugging purposes it may be convenient to work with a [`LambdaActor`](@ref). This provides an interface that defines callbacks for "next", "error" and "complete" events.

```julia
using Rx

source = from([1, 2, 3])

subscribe!(source, LambdaActor{Int}(
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

!!! tip "Performance tip"
    It is better to avoid `LambdaActor`s in production code. Because a `LambdaActor` uses `Base.invokelatest` for callback invocation, it may affect performance dramatically.
