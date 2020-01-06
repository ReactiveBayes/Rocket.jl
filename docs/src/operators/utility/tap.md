# [Tap Operator](@id operator_tap)

```@docs
tap
```

## Description

Returns an Observable that resembles the source Observable, but modifies it so that the provided Observer is called to perform a side effect for every value emitted by the source.

This operator is useful for debugging your Observables, verifying correct values, or performing other side effects.

Note: this operator differs from a subscribe on the Observable. If the Observable returned by tap is not subscribed, the side effects specified by the Observer will never happen. tap therefore simply spies on existing execution, it does not trigger an execution to happen like subscribe does.

!!! tip "Performance tip"
    Do not use lambda based operators in real Julia code as them lack of performance. Either use macro helpers to generate efficient versions of operators (like [`@CreateMapOperator()`](@ref operator_map) and/or [`@CreateFilterOperator()`](@ref operator_filter), etc..) or implement your own operators without using lambda functions.

## @CreateTapOperator macro

For performance reasons Rx.jl library provides a special macro for creating custom tap operators.

```@docs
@CreateTapOperator
```

## See also

[Operators](@ref what_are_operators)
