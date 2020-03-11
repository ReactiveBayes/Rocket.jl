# [TakeUntil Operator](@id operator_take_until)

```@docs
take_until
```

## Description

`take_until` subscribes and begins mirroring the source Observable. It also monitors a second Observable, notifier that you provide. If the notifier emits a value, the output Observable stops mirroring the source Observable and completes. If the notifier doesn't emit any value and completes then takeUntil will pass all values.

## See also

[Operators](@ref what_are_operators)
