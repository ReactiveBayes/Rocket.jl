# [Operators](@id section_operators)

Even though the Observable is the foundation, reactive extensions is mostly useful because of its __operators__. Operators are the essential pieces that allow complex asynchronous code to be easily composed in a declarative manner.

## [What are operators?](@id what_are_operators)

There are two kinds of operators:

## Pipeable operators

Pipeable Operators are the kind that can be piped to Observables using the syntax `source |> operator()`. These include the [`filter()`](@ref) and [`map()`](@ref operator_map) operators. When called, operators __do not change__ the existing Observable instance. Instead, they return a __new__ Observable, whose subscription logic is based on the first Observable.

!!! note
    A Pipeable Operator is a function that takes an Observable as its input and returns another Observable. It is a pure operation: the previous Observable remains unmodified.

A __Pipeable Operator__ is essentially a pure callable object that accepts one Observable as input and returns another Observable as output. Subscribing to the output Observable will also subscribe to the input Observable.

For example, the operator called [`map()`](@ref operator_map) is analogous to the Array method of the same name. Just like the array method `map((d) -> d ^ 2, [ 1, 2, 3 ])` yields `[ 1, 4, 9 ]`, the Observable emits `1`, `4`, `9`:

```julia
source = from([ 1, 2, 3 ])
subscribe!(source |> map(Int, (d) -> d ^ 2), lambda(
    on_next = (d) -> println(d)
))

// Logs:
// 1
// 4
// 9
```

Another useful operator is [`first()`](@ref):

```julia
source = from([ 1, 2, 3 ])
subscribe!(source |> first(), lambda(
    on_next     = (d) -> println(d),
    on_complete = ()  -> "Completed"
))

// Logs:
// 1
// Completed
```

## Creation operators

Distinct from pipeable operators, creation operators are functions that can be used to create an Observable with some common predefined behavior or by joining other Observables. For example: [`from([ 1, 2, 3 ])`](@ref observable_array) creates an observable that will sequentially emit 1, 2, and 3.

```julia
source = from([ 1, 2, 3 ])
subscribe!(source, lambda(
    on_next     = (d) -> println("Value: $d"),
    on_error    = (e) -> println("Oh no, error: $e")
    on_complete = ()  -> println("Completed")
))

// Logs:
// Value: 1
// Value: 2
// Value: 3
// Completed
```

## Operators piping

Pipeable operators are special objects that can be used like ordinary functions with
`on_call!(operator, source)`. In practice however they tend to accumulate and quickly grow unreadable: `on_call!(operator1, on_call!(operator2, on_call!(operator3, source)))`. Therefore, Rocket.jl overloads `|>` for operators and Observables:

```julia
using Rocket

source = from(1:100) |> filter((d) -> d % 2 === 0) |> map(Int, (d) -> d ^ 2) |> sum()

subscribe!(source, logger())

// Logs
// [LogActor] Data: 171700
// [LogActor] Completed
```

It is also possible to create an operator composition with `+` or `|>`. It might be useful to create an alias for some often used operator chain

```julia
using Rocket

mapAndFilter = map(Int, d -> d ^ 2) + filter(d -> d % 2 == 0) 

source = from(1:5) |> mapAndFilter

subscribe!(source, logger())

// Logs
// [LogActor] Data: 4
// [LogActor] Data: 16
// [LogActor] Completed

mapAndFilterAndSum = mapAndFilter + sum()

source = from(1:5) |> mapAndFilterAndSum

subscribe!(source, logger())

// Logs
// [LogActor] Data: 20
// [LogActor] Completed
```

For stylistic reasons, `on_call!(operator, source)` is never used in practice - even if there is only one operator. Instead, `source |> operator()` is generally preferred.
