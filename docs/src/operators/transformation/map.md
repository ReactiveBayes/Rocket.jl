# [Map Operator](@id operator_map)

```@docs
map
```

## Description

Like `map(f, array)`, it passes each source value through a transformation function to get corresponding output values.

!!! tip "Performance tip"
    Do not use lambda based operators in real Julia code as them lack of performance. Either use macro helpers to generate efficient versions of operators (like [`@CreateMapOperator()`](@ref operator_map) and/or [`@CreateFilterOperator()`](@ref operator_filter), etc..) or implement your own operators without using lambda functions.

## @CreateMapOperator macro

For performance reasons Rx.jl library provides a special macro for creating custom (and pure) map operators.

```@docs
@CreateMapOperator
```

## See also

[Operators](@ref what_are_operators)
