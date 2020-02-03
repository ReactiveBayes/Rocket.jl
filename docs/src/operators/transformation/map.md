# [Map Operator](@id operator_map)

```@docs
map
```

## Description

Like `map(f, array)`, the `map` operator applies a function to each source value.

!!! tip "Performance tip"
    For performance reasons, do not use lambda based operators in production Julia code. Either use macro helpers to generate efficient versions of operators (like [`@CreateMapOperator()`](@ref operator_map) and/or [`@CreateFilterOperator()`](@ref operator_filter), etc..) or implement your own operators without using lambda functions.

## @CreateMapOperator macro

For performance reasons Rocket.jl library provides a special macro for creating custom (and pure) map operators.

```@docs
@CreateMapOperator
```

## See also

[Operators](@ref what_are_operators)
