# Operators

Rx is mostly useful for its __operators__, even though the Observable is the foundation. Operators are the essential pieces that allow complex asynchronous code to be easily composed in a declarative manner.

## [What are operators?](@id what_are_operators)

There are two kinds of operators:

## Pipeable operators

Pipeable Operators are the kind that can be piped to Observables using the syntax `source |> operator()`. These includes, [`filter()`](@ref), and [`map()`](@ref operator_map).
When called, they __do not change__ the existing Observable instance. Instead, they return a __new__ Observable, whose subscription logic is based on the first Observable.

!!! note
    A Pipeable Operator is a function that takes an Observable as its input and returns another Observable. It is a pure operation: the previous Observable stays unmodified.

A __Pipeable Operator__ is essentially a pure callable object which takes one Observable as input and generates another Observable as output. Subscribing to the output Observable will also subscribe to the input Observable.

For example, the operator called [`map()`](@ref operator_map) is analogous to the Array method of the same name. Just as `map((d) -> d ^ 2, [ 1, 2, 3 ])` will yield `[ 1, 4, 9 ]`, the Observable created like this:

```julia
source = from([ 1, 2, 3 ])
subscribe!(source |> map(Int, Int, (d) -> d ^ 2), LambdaActor{Int}(
    on_next = (d) -> println(d)
))

// Logs:
// 1
// 4
// 9
```

will emit `1`, `4`, `9`. Another useful operator is [`first()`](@ref):

```julia
source = from([ 1, 2, 3 ])
subscribe!(source |> first(Int), LambdaActor{Int}(
    on_next     = (d) -> println(d),
    on_complete = ()  -> "Completed"
))

// Logs:
// 1
// Completed
```

Note that [`map()`](@ref operator_map) logically must be constructed on the fly, since it must be given the mapping function to. By contrast, [`first()`](@ref) could be a constant, but it is nonetheless constructed on the fly. As a general practice, all operators are constructed, whether they need arguments or not.

!!! tip "Performance tip"
    Do not use lambda based operators in real Julia code as them lack of performance. Either use macro helpers to generate efficient versions of operators (like [`@CreateMapOperator()`](@ref operator_map) and/or [`@CreateFilterOperator()`](@ref operator_filter), etc..) or implement your own operators without using lambda functions.

## Creation operators

What are creation operators? Distinct from pipeable operators, creation operators are functions that can be used to create an Observable with some common predefined behavior or by joining other Observables. For example: `from([ 1, 2, 3 ])` creates an observable that will emit 1, 2, and 3, one right after another.

```julia
source = from([ 1, 2, 3 ])
subscribe!(source, LambdaActor{Int}(
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
