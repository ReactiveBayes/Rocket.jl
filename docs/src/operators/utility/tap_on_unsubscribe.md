# [TapOnUnsubscribe Operator](@id operator_tap_on_unsubscribe)

```@docs
TapBeforeUnsubscription
TapAfterUnsubscription
tap_on_unsubscribe
```

## Description

Returns an Observable that resembles the source Observable, but modifies it so that the provided Observer is called to perform a side effect on unsubscription from the source.

This operator is useful for debugging your Observables, verifying correctness, or performing other side effects.

## See also

[Operators](@ref what_are_operators)
