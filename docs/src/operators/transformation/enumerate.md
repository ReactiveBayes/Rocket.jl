# [Enumerate Operator](@id operator_enumerate)

```@docs
enumerate
```

## Description

`enumerate` operator returns an Observable, which converts each value emitted by the source Observable into a tuple of its order number and the value itself.

## Example

Get a value from the source with its order number

```julia
using Rx

source = from([ 0.0, 0.2, 0.4, 0.6, 0.8, 1.0 ])
subscribe!(source |> enumerate(Float64), LoggerActor{Tuple{Float64, Int}}())

# output

[LogActor] Data: (0.0, 1)
[LogActor] Data: (0.2, 2)
[LogActor] Data: (0.4, 3)
[LogActor] Data: (0.6, 4)
[LogActor] Data: (0.8, 5)
[LogActor] Data: (1.0, 6)
[LogActor] Completed
```

## See also

[Operators](@ref what_are_operators), [`scan`](@ref operator_scan)
