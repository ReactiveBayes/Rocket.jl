# [Take Operator](@id operator_take)

```@docs
take
```

## Description

`take` returns an Observable that emits only the first `count` values emitted by the source Observable. If the source emits fewer than `count` values, then all of its values are emitted. Afterwards, the Observable completes regardless of whether the source completed.

## See also

[Operators](@ref what_are_operators)
