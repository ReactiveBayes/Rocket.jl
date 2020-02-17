# [Reduce Operator](@id operator_reduce)

```@docs
reduce
```

## Description

`reduce` applies an accumulator function to each value of the source Observable (from the past) and reduces it to a single value that is emitted by the output Observable. Note that reduce will only emit one value, only when the source Observable completes. It is equivalent to applying [`scan`](@ref operator_scan) followed by [`last`](@ref operator_last).

It returns an Observable that applies a specified accumulator function to each item emitted by the source Observable. If a `seed` value is specified, then that value will be used as the initial value of the accumulator. If no `seed` value is specified, the first item of the source is used as the seed.

## See also

[Operators](@ref what_are_operators), [`scan`](@ref operator_scan), [`last`](@ref operator_last)
