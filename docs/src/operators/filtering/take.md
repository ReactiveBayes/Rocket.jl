# [Take Operator](@id operator_take)

```@docs
take
```

## Description

`take` returns an Observable that emits only the first count values emitted by the source Observable. If the source emits fewer than count values then all of its values are emitted. After that, it completes, regardless if the source completes.

## Example

Take the first `5` elements of the source Observable

```julia
using Rx

source = from([ i for i in 1:100 ])
subscribe!(source |> take(Int, 5), LoggerActor{Int}())

# output

[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Data: 3
[LogActor] Data: 4
[LogActor] Data: 5
[LogActor] Completed
```

## See also

[Operators](@ref what_are_operators)
