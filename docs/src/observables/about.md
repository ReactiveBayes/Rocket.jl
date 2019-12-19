# [Observables](@id section_observables)

Observables are lazy Push collections of multiple values. They fill the missing spot in the following table:

 Type | Single   | Mutliple   |
 :--- | :------- | :--------- |
 Pull | Function | Iterator   |
 Push | Promise  | __Observable__ |

## First example

For example the following is an Observable that pushes the values 1, 2, 3 immediately (synchronously) when subscribed, and the value 4 after one second has passed since the subscribe call, then completes:

```julia
using Rx

source = make(Int) do actor
    next!(actor, 1)
    next!(actor, 2)
    next!(actor, 3)
    setTimeout(1000) do
        next!(actor, 4)
        complete!(actor)
    end
end
```

To invoke the Observable and see these values, we need to subscribe to it:

```julia
using Rx

source = make(Int) do actor
    next!(actor, 1)
    next!(actor, 2)
    next!(actor, 3)
    setTimeout(1000) do
        next!(actor, 4)
        complete!(actor)
    end
end

println("Just before subscribe")
subscribe!(source, LambdaActor{Int}(
    on_next     = (d) -> println(d),
    on_complete = ()  -> println("Completed")
))
println("Just after subscribe")

# Logs
# Just before subscribe
# 1
# 2
# 3
# Just after subscribe
# 4
# Completed
```

## Pull vs Push

__Pull__ and __Push__ are two different protocols that describe how a data __Producer__ can communicate with a data __Consumer__.

What is Pull? In Pull systems, the Consumer determines when it receives data from the data Producer. The Producer itself is unaware of when the data will be delivered to the Consumer.

Every Julia Function is a Pull system. The function is a Producer of data, and the code that calls the function is consuming it by "pulling" out a single return value from its call.

Type | PRODUCER   | CONSUMER   |
:--- | :------- | :--------- |
Pull | Passive: produces data when requested. | Active: decides when data is requested.   |
Push | Active: produces data at its own pace.  | Passive: reacts to received data. |

What is Push? In Push systems, the Producer determines when to send data to the Consumer. The Consumer is unaware of when it will receive that data.

If you are familiar with [Futures and promises](https://en.wikipedia.org/wiki/Futures_and_promises) you already know that they are the most common type of Push system today. A Promise (the Producer) delivers a resolved value to registered callbacks (the Consumers), but unlike functions, it is the Promise which is in charge of determining precisely when that value is "pushed" to the callbacks.

Rx.jl introduces Observables, a new Push system for Julia. An Observable is a Producer of multiple values, "pushing" them to Observers (Consumers or [`Actors`](@ref section_actors)).

- A __Function__ is a lazily evaluated computation that synchronously returns a single value on invocation.
- A __Generator__ is a lazily evaluated computation that synchronously returns zero to (potentially) infinite values on iteration.
- A __Promise__ is a computation that may (or may not) eventually return a single value.
- An __Observable__ is a lazily evaluated computation that can synchronously or asynchronously return zero to (potentially) infinite values from the time it's invoked onwards.

## Observables as generalizations of functions

What is the difference between an Observable and a function? Observables can "return" multiple values over time, something which functions cannot. You can't do this:

```julia
function foo()
    println("Hello!")
    return 0
    return 1 # Dead code, will never happen
end
```

Functions can only return one value. Observables, however, can do this:

```
using Rx

foo = make(Int) do actor
    next!(actor, 0)
    next!(actor, 1)
    complete!(actor)
end

```

But you can also "return" values asynchronously:

```
using Rx

foo = make(Int) do actor
    setTimeout(1000) do
        next!(actor, 0)
        complete!(actor)
    end
end
```

- `func()` means __"give me one value synchronously"__
- `subscribe(observable, ...)` means __"give me any amount of values, either synchronously or asynchronously"__

## Anatomy of an Observable

Observables are created using [creation operators](@ref operators_list) (it is also possible to build an Observable from scratch with custom logic), are subscribed to with an [`Actor`](@ref section_actors), execute to deliver `next!` / `error!` / `complete!` notifications to the Actor, and their execution may be disposed. These four aspects are all encoded in an Observable instance, but some of these aspects are related to other types, like [`Subscribable`](@ref observables_api) and [`Subscription`](@ref teardown_api).

Core Observable concerns:

- Creating Observables
- Subscribing to Observables
- Executing the Observable
- Disposing Observables

### Creating Observables

You can create an Observable with various ways using [Creation operators](@ref operators_list).
You can also build an Observable from scratch. To see how you can build an Observable with custom logic from scratch consult the [API Section](@ref observables_api).

### Subscribing to Observables

The Observable `source` in the example can be subscribed to, like this:

```julia
using Rx

subscribe!(source, LambdaActor{Int}(
    on_next = (d) -> println(d)
))
```

This shows how subscribe calls are not shared among multiple Actors of the same Observable. When calling `subscribe!` with an Actor, the function `on_subscribe!` attached for this particular Observable is run for that given actor. Each call to `subscribe!` triggers its own independent setup for that given actor.

!!! note
    Subscribing to an Observable is like calling a function, providing callbacks where the data will be delivered to.

A `subscribe!` call is simply a way to start an "Observable execution" and deliver values or events to an Actor of that execution.

### Executing Observables

The execution produces multiple values over time, either synchronously or asynchronously.

There are three types of values an Observable Execution can deliver:

- __Next__ notification: sends a value such as a Int, a String, an Dict, etc.
- __Error__ notification: sends any value (assuming this is an error)
- __Complete__ notification: does not send a value.

"Next" notifications are the most important and most common type: they represent actual data being delivered to an subscriber. "Error" and "Complete" notifications may happen only once during the Observable Execution, and there can only be either one of them.

!!! note
    In an Observable Execution, zero to infinite Next notifications may be delivered. If either an Error or Complete notification is delivered, then nothing else can be delivered afterwards.

The following is an example of an Observable execution that delivers three Next notifications, then completes:

```julia
using Rx

source = make(Int) do actor
    next!(actor, 1)
    next!(actor, 2)
    next!(actor, 3)
    complete!(actor)
end

# or the same with creation operator

source = from([ 1, 2, 3 ])
```

It is a good idea to wrap any code in subscribe with try/catch block that will deliver an Error notification if it catches an exception:

```julia
using Rx

source = make(Int) do actor
    try
        next!(actor, 1)
        next!(actor, 2)
        next!(actor, 3)
        complete!(actor)
    catch e
        error!(actor, e)
    end
end

```

### Disposing Observable Executions

Because Observable Executions may be infinite, and it's common for an Actor to want to abort execution in finite time, we need an API for canceling an execution. Since each execution is exclusive to one Actor only, once the Actor is done receiving values, it has to have a way to stop the execution, in order to avoid wasting computation power or memory resources.

When `subscribe!` is called, the Actor gets attached to the newly created Observable execution. This call also returns an object, the [`Subscription`](@ref section_subscription):

```julia
subscription = subscribe!(source, actor)
```

The Subscription represents the ongoing execution, and has a minimal API which allows you to cancel that execution. Read more about [`Subscription type here`](@ref section_subscription).

With

```julia
unsubscribe!(subscription)
```

you can cancel the ongoing execution.

!!! note
    When you `subscribe!`, you get back a Subscription, which represents the ongoing execution. Just call `unsubscribe!` to cancel the execution.
