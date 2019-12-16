# [Sum Operator](@id operator_sum)

```@docs
sum
```

## Description

The `sum` operator operates on an Observable of objects for which `+` is defined, and when source Observable completes it emits a single item: sum of all of the previous items. The `sum` operator is similar to `reduce(T, T, +)` (see [`reduce`](@ref operator_reduce)).

If a `from` value is specified, then that value will be used as the initial value for the sum accumulator. If no `from` value is specified, the `zero(T)` is used as the initial.

## Example

Get the sum of a series of numbers

```julia
using Rx

source = from([ i for i in 1:42 ])
subscribe!(source |> sum(Int), LoggerActor{Int}())

# output

[LogActor] Data: 903
[LogActor] Completed
```

## See also

[Operators](@ref what_are_operators), [`reduce`](@ref operator_reduce)
