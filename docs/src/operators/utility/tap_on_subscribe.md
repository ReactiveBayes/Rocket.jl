# [TapOnSubscribe Operator](@id operator_tap_on_subscribe)

```@docs
tap_on_subscribe
```

## Description

Returns an Observable that resembles the source Observable, but modifies it so that the provided Observer is called to perform a side effect on subscription to the source.

This operator is useful for debugging your Observables, verifying correctness, or performing other side effects.

Note: this operator differs from a subscribe on the Observable. If the Observable returned by `tap_on_subscribe` is not subscribed, the side effects specified by the Observer will never happen. `tap_on_subscribe` therefore simply spies on future execution, it does not trigger an execution to happen like subscribe does.

## See also

[Operators](@ref what_are_operators)
