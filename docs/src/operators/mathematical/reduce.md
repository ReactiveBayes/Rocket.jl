# [Reduce Operator](@id operator_reduce)

```@docs
reduce
```

## Description

`reduce` applies an accumulator function against an accumulation and each value of the source Observable (from the past) to reduce it to a single value, emitted on the output Observable. Note that reduce will only emit one value, only when the source Observable completes. It is equivalent to applying operator [`scan`](@ref operator_scan) followed by operator [`last`](@ref operator_last).

Returns an Observable that applies a specified accumulator function to each item emitted by the source Observable. If a `seed` value is specified, then that value will be used as
the initial value for the accumulator. If no `seed` value is specified, the first item of the source is used as the seed.

!!! tip "Performance tip"
    Do not use lambda based operators in real Julia code as them lack of performance. Either use macro helpers to generate efficient versions of operators (like [`@CreateMapOperator()`](@ref operator_map) and/or [`@CreateFilterOperator()`](@ref operator_filter), etc..) or implement your own operators without using lambda functions.

## @CreateReduceOperator macro

For performance reasons Rx.jl library provides a special macro for creating custom (and pure) reduce operators.

```@docs
@CreateReduceOperator
```

## See also

[Operators](@ref what_are_operators), [`scan`](@ref operator_scan), [`last`](@ref operator_last)
