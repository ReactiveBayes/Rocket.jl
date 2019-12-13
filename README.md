# Reactive extensions library for Julia

Rx.jl is a Julia package for reactive programming using Observables, to make it easier to compose asynchronous and actor based code.

In order to achieve best performance and convenient API Rx.jl combines [Observer pattern](https://en.wikipedia.org/wiki/Observer_pattern), [Actor model](https://en.wikipedia.org/wiki/Actor_model) and [Functional programming](https://en.wikipedia.org/wiki/Functional_programming).

We designed Rx.jl with a focus on performance and modularity.

The essential concepts in Rx.jl are:

- __Observable__: represents a collection of future messages (data or/and events).
- __Actor__: is an object that knows how to react on incoming messages delivered by the __Observable__.
- __Subscription__: represents a teardown logic which might be useful for cancelling the execution of an __Observable__.
- __Operators__: are objects that enable a functional programming style to dealing with collections with operations like `map`, `filter`, `reduce`, etc.
- __Subject__: the way of multicasting a message to multiple Observers.

## First example

Normally you use an arrays for processing some data.

```Julia
for value in array_of_values
    doSomethingWithMyData(value)
end
```

Using Rx.jl you will use a subscription pattern instead.

```Julia
subscribe!(source_of_values, LambdaActor{TypeOfData}(
    on_next  = (data)  -> doSomethingWithMyData(data),
    on_error = (error) -> doSomethingWithAnError(error),
    complete = ()      -> println("Completed! You deserve some coffee man")
))
```

| Tip | Do not use lambda functions for real computations as it lacks of performance. Use an Actor based approach instead. |
| --- | - |

## Operators

What makes Rx.jl powerful is its ability to help you process, transform and modify the messages flow through your observables using __Operators__.

```Julia
squared_int_values = source_of_int_values |> map(Int, Int, (d) -> d ^ 2)
subscribe!(squared_int_values, LambdaActor{Int}(
    on_next = (data) -> println(data)
))
```

You can also use a special macro which is defined for some operators to produce an optimized versions of some operations on observables without using the callbacks.

```Julia
@CreateMapOperator("Squared", (d) -> d ^ 2)
squared_int_values = source_of_int_values |> SquaredMapOperator{Int, Int}()
```
