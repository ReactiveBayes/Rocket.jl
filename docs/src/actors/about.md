# [Actors](@id section_actors)

What is an __Actor__? An actor is the primitive unit of computation.
It’s the thing that receives a message and do some kind of computation based on it.

The idea is very similar to what we have in object-oriented languages: An object receives a message (a method call) and does something depending on which message it receives (which method we are calling).
The main difference is that actors are completely isolated from each other and they will never share memory. It’s also worth noting that an actor can maintain a private state that can never be changed directly by another actor.

For quick introduction into Actor model see this [article](https://www.brianstorti.com/the-actor-model/).

The API of Rx.jl's Actors is similar to [RxJS](https://rxjs.dev/guide/overview) subscribers.

## First example

For example the following is an Actor that keeps every received value from an Observable.

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

Actor may be not interested in values itself, but only for a completion event. In such case Rx.jl provides a [`CompletionActor`](@ref) abstract type.

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

For debugging purposes it may be convenient to work with [`LambdaActor`](@ref). It provides an interface to define a callbacks for next, error and complete events.

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
    Is it better to avoid using `LambdaActor` in final code as it is using `Base.invokelatest` for callback invokation and it may affect performance dramatically.
