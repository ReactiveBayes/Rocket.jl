# [Filter Operator](@id operator_filter)

```@docs
filter
```

## Description

Like `filter(f, array)`, this operator takes values from the source Observable, passes them through a predicate function and only emits those values that yielded `true`.

!!! tip "Performance tip"
    For performance reasons, do not use lambda-based operators in production Julia code. Either use macro helpers to generate efficient versions of operators (like [`@CreateMapOperator()`](@ref operator_map) or [`@CreateFilterOperator()`](@ref operator_filter), etc..), or implement custom operators without using lambda functions.

## @CreateFilterOperator macro

For performance reasons, the Rocket.jl library provides a special macro for creating custom (and pure) filter operators.

```@docs
@CreateFilterOperator
```

## See also

[Operators](@ref what_are_operators)
