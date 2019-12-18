# [Sum Operator](@id operator_sum)

```@docs
sum
```

## Description

The `sum` operator operates on an Observable of objects for which `+` is defined, and when source Observable completes it emits a single item: sum of all of the previous items. The `sum` operator is similar to `reduce(T, T, +)` (see [`reduce`](@ref operator_reduce)).

## See also

[Operators](@ref what_are_operators), [`reduce`](@ref operator_reduce)
