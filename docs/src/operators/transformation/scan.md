# [Scan Operator](@id operator_scan)

```@docs
scan
```

## Description

Combines all values emitted by the source, using an accumulator function that joins a new source value with the past accumulation. This is similar to [`reduce`](@ref operator_reduce), but emits the intermediate accumulations.

Returns an Observable that applies a specified accumulator function to each item emitted by the source Observable. If a `seed` value is specified, then that value will be used as the initial value for the accumulator. If no `seed` value is specified, the first item of the source is used as the seed.

!!! tip "Performance tip"
    For performance reasons, do not use lambda based operators in production Julia code. Either use macro helpers to generate efficient versions of operators (like [`@CreateMapOperator()`](@ref operator_map) and/or [`@CreateFilterOperator()`](@ref operator_filter), etc..) or implement your own operators without using lambda functions.

## @CreateScanOperator macro

For performance reasons, the Rocket.jl library provides a special macro for creating custom (and pure) scan operators.

```@docs
@CreateScanOperator
```

## See also

[Operators](@ref what_are_operators)
