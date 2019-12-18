# [Take Operator](@id operator_take)

```@docs
take
```

## Description

`take` returns an Observable that emits only the first count values emitted by the source Observable. If the source emits fewer than count values then all of its values are emitted. After that, it completes, regardless if the source completes.

## See also

[Operators](@ref what_are_operators)
