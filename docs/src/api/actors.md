# [Actors API](@id actors_api)

## How to create a custom Actor

Any actor-like object should simply implement [`on_next!`](@ref), [`on_error!`](@ref) and [`on_complete!`](@ref) methods.

```@docs
Rocket.on_next!
Rocket.on_error!
Rocket.on_complete!
```

```@example actors_api
using Rocket

struct MyCustomActor end

function Rocket.on_next!(actor::MyCustomActor, data::Int) 
    println("Received data of type Int: ", data)
end

function Rocket.on_next!(actor::MyCustomActor, data::Float64) 
    println("Received data of type Float64: ", data)
end

function Rocket.on_next!(actor::MyCustomActor, data) 
    println("Received data of type ", typeof(data), ": ", data)
end

function Rocket.on_error!(actor::MyCustomActor, err) 
    showerror(err)
end

function Rocket.on_complete!(actor::MyCustomActor)
    println("Received a completion event")
end

```

```@example actors_api
source       = from_iterable(Any[ 1.0, 1, "Hello, world!" ])
subscription = subscribe!(source, MyCustomActor())
nothing #hide
```

Any actor can have internal state storage:

```@example actors_api
struct MyKeepIntActor
    values :: Vector{Int}

    MyKeepIntActor() = new(Vector{Int}())
end

Rocket.on_next!(actor::MyKeepIntActor, data::Int) = push!(actor.values, data)
Rocket.on_error!(actor::MyKeepIntActor, err)      = error(err)
Rocket.on_complete!(actor::MyKeepIntActor)        = begin end
nothing #hide
```

```@example actors_api
actor        = MyKeepIntActor()
source       = from_iterable(1:5)
subscription = subscribe!(source, actor)
nothing #hide
```

```@example actor_api
actor.values
```

## Errors

```@docs
Rocket.MissingDataArgumentInNextCall
Rocket.MissingErrorArgumentInErrorCall
```
