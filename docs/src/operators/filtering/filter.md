# [Filter Operator](@id operator_filter)

```@docs
filter
```

## Description

Like `filter(f, array)`, this operator takes values from the source Observable, passes them through a predicate function and only emits those values that yielded `true`.

!!! tip "Performance tip"
    Do not use lambda based operators in real Julia code as them lack of performance. Either use macro helpers to generate efficient versions of operators (like [`@CreateMapOperator()`](@ref operator_map) and/or [`@CreateFilterOperator()`](@ref operator_filter), etc..) or implement your own operators without using lambda functions.

## @CreateFilterOperator macro

For performance reasons Rx.jl library provides a special macro for creating custom (and pure) filter operators.

```@docs
@CreateFilterOperator
```

## See also

[Operators](@ref what_are_operators)
