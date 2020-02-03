# [Reduce Operator](@id operator_reduce)

```@docs
reduce
```

## Description

`reduce` applies an accumulator function to each value of the source Observable (from the past) and reduces it to a single value that is emitted by the output Observable. Note that reduce will only emit one value, only when the source Observable completes. It is equivalent to applying [`scan`](@ref operator_scan) followed by [`last`](@ref operator_last).

It returns an Observable that applies a specified accumulator function to each item emitted by the source Observable. If a `seed` value is specified, then that value will be used as the initial value of the accumulator. If no `seed` value is specified, the first item of the source is used as the seed.

!!! tip "Performance tip"
    For performance reasons, do not use lambda based operators in production Julia code. Either use macro helpers to generate efficient versions of operators (like [`@CreateMapOperator()`](@ref operator_map) or [`@CreateFilterOperator()`](@ref operator_filter), etc..), or implement custom operators without using lambda functions.

## @CreateReduceOperator macro

For performance reasons Rocket.jl library provides a special macro for creating custom (and pure) reduce operators.

```@docs
@CreateReduceOperator
```

## See also

[Operators](@ref what_are_operators), [`scan`](@ref operator_scan), [`last`](@ref operator_last)
