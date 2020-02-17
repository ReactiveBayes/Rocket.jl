# [Scan Operator](@id operator_scan)

```@docs
scan
```

## Description

Combines all values emitted by the source, using an accumulator function that joins a new source value with the past accumulation. This is similar to [`reduce`](@ref operator_reduce), but emits the intermediate accumulations.

Returns an Observable that applies a specified accumulator function to each item emitted by the source Observable. If a `seed` value is specified, then that value will be used as the initial value for the accumulator. If no `seed` value is specified, the first item of the source is used as the seed.

## See also

[Operators](@ref what_are_operators)
