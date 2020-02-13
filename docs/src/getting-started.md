# Getting started

Rocket.jl is a Julia package for reactive programming that makes it easier to work with asynchronous data. It is inspired by the [RxJS](https://github.com/ReactiveX/rxjs) and [ReactiveX](https://github.com/ReactiveX) communities.

In order to combine good performance with a convenient API, Rocket.jl employs [Observer patterns](https://en.wikipedia.org/wiki/Observer_pattern), [Actor models](https://en.wikipedia.org/wiki/Actor_model) and [Functional programming](https://en.wikipedia.org/wiki/Functional_programming).

## Installation

Install Rocket.jl through the Julia package manager:

```Julia
] add Rocket
```

## Concepts

Rocket.jl has been designed with a focus on performance and modularity.

The essential concepts in Rocket.jl are:

- [__Observable__](@ref section_observables): represents a collection of future messages (data or/and events).
- [__Actor__](@ref section_actors): is an object that knows how to react on incoming messages delivered by the __Observable__.
- [__Subscription__](@ref section_subscription): represents a teardown logic that is useful for cancelling the execution of an __Observable__.
- [__Operator__](@ref section_operators): an object that deals with collection operations, such as [`map`](@ref operator_map), [`filter`](@ref operator_filter), [`reduce`](@ref operator_reduce), etc.
- [__Subject__](@ref section_subjects): the way of multicasting a message to multiple Observers.

## First example

Conventionally, arrays are used for processing data.

```Julia
for value in array_of_values
    doSomethingWithMyData(value)
end
```

In contrast, Rocket.jl uses observables.

```Julia
subscription = subscribe!(source_of_values, lambda(
    on_next     = (data)  -> doSomethingWithMyData(data),
    on_error    = (error) -> doSomethingWithAnError(error),
    on_complete = ()      -> println("Completed!")
))
```

At some point in time you may decide to stop listening for new messages.

```Julia
unsubscribe!(subscription)
```

## Actors

In order to process messages from an observable you will need to define an Actor that knows how to react to incoming messages.

```Julia
struct MyActor <: Rocket.Actor{Int} end

Rocket.on_next!(actor::MyActor, data::Int) = doSomethingWithMyData(data)
Rocket.on_error!(actor::MyActor, error)    = doSomethingWithAnError(error)
Rocket.on_complete!(actor::MyActor)        = println("Completed!")
```

An actor can also have its own local state.

```Julia
struct StoreActor{D} <: Rocket.Actor{}
    values :: Vector{D}

    StoreActor{D}() where D = new(Vector{D}())
end

Rocket.on_next!(actor::StoreActor{D}, data::D) where D = push!(actor.values, data)
Rocket.on_error!(actor::StoreActor, error)             = doSomethingWithAnError(error)
Rocket.on_complete!(actor::StoreActor)                 = println("Completed: $(actor.values)")
```

For debugging purposes you can use a general [`LambdaActor`](@ref) actor.

## Operators

What makes Rocket.jl powerful is its ability to help you process, transform and modify the messages that flow through your observables, using [__Operators__](@ref section_operators).

```Julia
subscribe!(squared_int_values |> map(Int, (d) -> d ^ 2), LambdaActor{Int}(
    on_next = (data) -> println(data)
))
```

You can also use a special macro which is defined for some operators to produce an optimized version of some operations on observables, without using the callbacks.

```Julia
@CreateMapOperator("SquaredInt", Int, Int, (d) -> d ^ 2)
squared_int_values = source_of_int_values |> SquaredIntMapOperator()
```

Below is a performance comparison between different approaches, with an Observable of 500 integers and a `StoreActor`.

|      | Using regular array | Using macro generated map operator | Using lambda based map operator |
|------|---------------------|------------------------------------|---------------------------------|
| Time |3.174 μs (9 allocations: 8.33 KiB)|3.489 μs (11 allocations: 8.36 KiB)|25.780 μs (489 allocations: 15.84 KiB)|
