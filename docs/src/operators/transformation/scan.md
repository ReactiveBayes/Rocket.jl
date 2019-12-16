# [Scan Operator](@id operator_scan)

```@docs
scan
```

## Description

Combines together all values emitted on the source, using an accumulator function that knows how to join a new source value into the accumulation from the past. Is similar to [`reduce`](@ref operator_reduce), but emits the intermediate accumulations.

Returns an Observable that applies a specified accumulator function to each item emitted by the source Observable. If a `initial` value is specified, then that value will be used as the initial value for the accumulator. If no `initial` value is specified, the `zero(R)` is used as the initial.

## Example

Accumulate every value into array:

```julia
using Rx

source = from([ 1, 2, 3 ])
subscribe!(source |> scan(Int, Vector{Int}, (d, c) -> [ c..., d ], Int[]), LoggerActor{Vector{Int}}())

# output

[LogActor] Data: [1]
[LogActor] Data: [1, 2]
[LogActor] Data: [1, 2, 3]
[LogActor] Completed
```

!!! tip "Performance tip"
    Do not use lambda based operators in real Julia code as them lack of performance. Either use macro helpers to generate efficient versions of operators (like [`@CreateMapOperator()`](@ref operator_map) and/or [`@CreateFilterOperator()`](@ref operator_filter), etc..) or implement your own operators without using lambda functions.

## @CreateScanOperator macro

For performance reasons Rx.jl library provides a special macro for creating custom (and pure) scan operators.

```@docs
@CreateScanOperator
```

## See also

[Operators](@ref what_are_operators)
