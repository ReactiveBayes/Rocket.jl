# Reactive extensions library for Julia

| **Documentation**                                                               | **Build Status**                                                                                |
|:-------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------------------------:|
| [![][docs-stable-img]][docs-stable-url] [![][docs-dev-img]][docs-dev-url] | [![][ci-img]][ci-url] [![][codecov-img]][codecov-url] |

[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://biaslab.github.io/Rocket.jl/dev

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://biaslab.github.io/Rocket.jl/stable

[ci-img]: https://github.com/biaslab/Rocket.jl/actions/workflows/ci.yml/badge.svg?branch=master
[ci-url]: https://github.com/biaslab/Rocket.jl/actions

[codecov-img]: https://codecov.io/gh/biaslab/Rocket.jl/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/biaslab/Rocket.jl?branch=master

Rocket.jl is a Julia package for reactive programming using Observables, to make it easier to work with asynchronous data.

In order to achieve best performance and convenient API Rocket.jl combines [Observer pattern](https://en.wikipedia.org/wiki/Observer_pattern), [Actor model](https://en.wikipedia.org/wiki/Actor_model) and [Functional programming](https://en.wikipedia.org/wiki/Functional_programming).

Inspired by [RxJS](https://github.com/ReactiveX/rxjs) and [ReactiveX](https://github.com/ReactiveX) communities.

Rocket.jl has been designed with a focus on performance and modularity.

The essential concepts in Rocket.jl are:

- __Observable__: represents a collection of future messages (data or/and events).
- __Actor__: is an object that knows how to react on incoming messages delivered by the __Observable__.
- __Subscription__: represents a teardown logic which might be useful for cancelling the execution of an __Observable__.
- __Operators__: are objects that enable a functional programming style to dealing with collections with operations like `map`, `filter`, `reduce`, etc.
- __Subject__: the way of multicasting a message to multiple Observers.

## Quick start

For a quick start and basic introduction take a look at the [demo folder](https://github.com/biaslab/Rocket.jl/tree/master/demo) and [Quick Start notebook](https://github.com/biaslab/Rocket.jl/blob/master/demo/00_quick_start.ipynb).

```Julia
using Rocket, Compose, IJulia ; set_default_graphic_size(35cm, 2cm)
```

```Julia
function draw_ball(t)
    IJulia.clear_output(true)
    x = -exp(-0.01t) + 1                     # x coordinate
    y = -abs(exp(-0.04t)*(cos(0.1t))) + 0.83 # y coordinate
    display(compose(context(), circle(x, y, 0.01)))
end
```

```Julia
source = interval(20) |> take(200) # Take only first 200 emissions

subscription = subscribe!(source, draw_ball)
```

![Alt Text](demo/pics/bouncing-ball.gif)

```Julia
unsubscribe!(subscription) # It is possible to unsubscribe before the stream ends    
IJulia.clear_output(false);
```


## Documentation

Full documentation is available at [BIASlab website](https://biaslab.github.io/Rocket.jl/stable).

It is also possible to build a documentation locally. Just execute

```bash
$ julia make.jl
```

in the `docs/` directory to build a local version of the documentation.

## First example

Normally you use an arrays for processing some data.

```Julia
for value in array_of_values
    doSomethingWithMyData(value)
end
```

In Rocket.jl you will use an observable.

```Julia
subscription = subscribe!(source_of_values, lambda(
    on_next     = (data)  -> doSomethingWithMyData(data),
    on_error    = (error) -> doSomethingWithAnError(error),
    on_complete = ()      -> println("Completed!")
))
```

At some point of time you may decide to stop listening for new messages.

```Julia
unsubscribe!(subscription)
```

## Actors

To process messages from an observable you have to define an Actor that know how to react on incoming messages.

```Julia
struct MyActor <: Rocket.Actor{Int} end

Rocket.on_next!(actor::MyActor, data::Int) = doSomethingWithMyData(data)
Rocket.on_error!(actor::MyActor, error)    = doSomethingWithAnError(error)
Rocket.on_complete!(actor::MyActor)        = println("Completed!")
```

Actor can also have its own local state

```Julia
struct StoreActor{D} <: Rocket.Actor{D}
    values :: Vector{D}

    StoreActor{D}() where D = new(Vector{D}())
end

Rocket.on_next!(actor::StoreActor{D}, data::D) where D = push!(actor.values, data)
Rocket.on_error!(actor::StoreActor, error)             = doSomethingWithAnError(error)
Rocket.on_complete!(actor::StoreActor)                 = println("Completed: $(actor.values)")
```

For debugging purposes you can use a general `LambdaActor` actor or just pass a function object as an actor in `subscribe!` function.

## Operators

What makes Rocket.jl powerful is its ability to help you process, transform and modify the messages flow through your observables using __Operators__.

List of all available operators can be found in the documentation ([link](https://biaslab.github.io/Rocket.jl/stable/operators/all/)).

```Julia
squared_int_values = source_of_int_values |> map(Int, (d) -> d ^ 2)
subscribe!(squared_int_values, lambda(
    on_next = (data) -> println(data)
))
```

## Rocket.jl is fast

Rocket.jl has been designed with a focus on efficiency, scalability and maximum performance. Below is a benchmark comparison between Rocket.jl, [Signals.jl](https://github.com/TsurHerman/Signals.jl), [Reactive.jl](https://github.com/JuliaGizmos/Reactive.jl) and [Observables.jl](https://github.com/JuliaGizmos/Observables.jl) in Julia v1.8.5 (see `versioninfo` below). 

We test map and filter operators latency in application to a finite stream of integers. Code is available in [demo folder](https://github.com/biaslab/Rocket.jl/tree/master/demo).

Rocket.jl outperforms Observables.jl, Reactive.jl and Signals.jl significantly in terms of execution times and memory consumption both in synchronous and asynchronous modes. 

![Rocket.jl vs Reactive.jl](demo/pics/reactive-rocket.svg?raw=true&sanitize=true "Rocket.jl vs Reactive.jl")

![Rocket.jl vs Signals.jl](demo/pics/signals-rocket.svg?raw=true&sanitize=true "Rocket.jl vs Signals.jl")

![Rocket.jl vs Observables.jl](demo/pics/observables-rocket.svg?raw=true&sanitize=true "Rocket.jl vs Observables.jl")

```julia
versioninfo()
```

```
Julia Version 1.8.5
Commit 17cfb8e65ea (2023-01-08 06:45 UTC)
Platform Info:
  OS: macOS (arm64-apple-darwin21.5.0)
  CPU: 10 × Apple M2 Pro
  WORD_SIZE: 64
  LIBM: libopenlibm
  LLVM: libLLVM-13.0.1 (ORCJIT, apple-m1)
  Threads: 1 on 6 virtual cores
```

```julia
] status
```

```
  [510215fc] Observables v0.5.4
  [a223df75] Reactive v0.8.3
  [df971d30] Rocket v1.6.0 
  [6303bc30] Signals v1.2.0
```
