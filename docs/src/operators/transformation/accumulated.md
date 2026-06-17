# [Accumulated Operator](@id operator_accumulated)

```@docs
accumulated
```

## Description

Combines all values emitted by the source, using an accumulator function that joins a new source value with all past emitted values into a single array. This is similar to [`scan`](@ref operator_scan) with a `vcat` accumulation function.

## See also

[Operators](@ref what_are_operators)
