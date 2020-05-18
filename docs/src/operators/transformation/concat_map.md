# [ConcatMap Operator](@id operator_concat_map)

```@docs
concat_map
```

## Description

Returns an Observable that emits items based on applying a function that you supply to each item emitted by the source Observable, where that function returns an (so-called "inner") Observable. Each new inner Observable is concatenated with the previous inner Observable.

!!! warning
    If source values arrive endlessly and faster than their corresponding inner Observables can complete, it will result in memory issues as inner Observables amass in an unbounded buffer waiting for their turn to be subscribed to.

!!! note
    `concat_map` is equivalent to `merge_map` with concurrency parameter set to 1.

## See also

[Operators](@ref what_are_operators), [`merge_map`](@ref)
