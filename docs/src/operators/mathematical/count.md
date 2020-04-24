# [Count Operator](@id operator_count)

```@docs
count
```

## Description

`count` transforms an Observable that emits values into an Observable that emits a single value that represents the number of values emitted by the source Observable. If the source Observable terminates with an error, count will pass this error notification along without emitting a value first. If the source Observable does not terminate at all, count will neither emit a value nor terminate.

## Example

Counts how many values source Observable have emitted before the complete event happened

```julia
using Rocket

source = from([ i for i in 1:42 ])
subscribe!(source |> count(), logger())

# output

[LogActor] Data: 42
[LogActor] Completed
```

## See also

[Operators](@ref what_are_operators)
