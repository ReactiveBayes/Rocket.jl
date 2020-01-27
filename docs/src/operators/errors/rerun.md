# [Rerun Operator](@id operator_rerun)

```@docs
rerun
```

# Description

Any and all items emitted by the source Observable will be emitted by the resulting Observable, even those emitted during failed subscriptions. For example, if an Observable fails at first but emits `[1, 2]` then succeeds the second time and emits: `[1, 2, 3, 4, 5]` then the complete stream of emissions and notifications would be: `[1, 2, 1, 2, 3, 4, 5, complete]`.

## See also

[Operators](@ref what_are_operators)
