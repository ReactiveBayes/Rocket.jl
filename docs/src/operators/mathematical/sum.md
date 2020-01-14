# [Sum Operator](@id operator_sum)

```@docs
sum
```

## Description

`sum` operates on an Observable of objects on which `+` is defined. When the source Observable completes, it emits the sum of all previous items. The `sum` operator is similar to `reduce(T, T, +)` (see [`reduce`](@ref operator_reduce)).

## See also

[Operators](@ref what_are_operators), [`reduce`](@ref operator_reduce)
