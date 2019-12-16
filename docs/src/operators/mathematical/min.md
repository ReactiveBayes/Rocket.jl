# [Min Operator](@id operator_min)

```@docs
min
```

## Description

The `min` operator operates on an Observable of comparable objects, and when source Observable completes it emits a single item: the item with the smallest value.

## Example

Get the minimal value of a series of numbers

```julia
using Rx

source = from([ i for i in 1:42 ])
subscribe!(source |> min(Int), LoggerActor{Int}())

# output

[LogActor] Data: 1
[LogActor] Completed
```

## See also

[Operators](@ref what_are_operators)
