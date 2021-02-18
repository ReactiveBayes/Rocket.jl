# [Accumulated Operator](@id operator_accumulated)

```@docs
accumulated
```

## Description

Combines all values emitted by the source, using an accumulator function that joins a new source value with the all past values emmited into one single array. This is similar to [`scan`](@ref operator_scan) with `vcat` accumulation function.

## See also

[Operators](@ref what_are_operators)
