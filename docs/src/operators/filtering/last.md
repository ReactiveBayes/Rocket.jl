# [Last Operator](@id operator_last)

```@docs
last
```

## Description

`last` operator returns an Observable that emits only the last item emitted by the source Observable.

## Example

Take the last element of the source Observable

```julia
using Rx

source = from([ i for i in 1:100 ])
subscribe!(source |> last(Int), LoggerActor{Int}())

# output

[LogActor] Data: 100
[LogActor] Completed
```

```julia
using Rx

source = from(Int[])
subscribe!(source |> last(Int), LoggerActor{Int}())

# output

[LogActor] Completed
```

## See also

[Operators](@ref what_are_operators)
