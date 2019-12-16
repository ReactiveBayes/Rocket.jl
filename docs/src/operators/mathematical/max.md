# [Max Operator](@id operator_max)

```@docs
max
```

## Description

The `max` operator operates on an Observable of comparable objects, and when source Observable completes it emits a single item: the item with the largest value.

## Example

Get the maximum value of a series of numbers

```julia
using Rx

source = from([ i for i in 1:42 ])
subscribe!(source |> max(Int), LoggerActor{Int}())

# output

[LogActor] Data: 42
[LogActor] Completed
```

## See also

[Operators](@ref what_are_operators)
