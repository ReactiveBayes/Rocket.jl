# [Combined Observable](@id observable_combined)

```@docs
combineLatest
PushEach
PushEachBut
PushNew
PushNewBut
PushStrategy
```

## Description

`combineLatest` combines the values from all Observables in its arguments. This is done by subscribing to each Observable in order and, whenever an Observable emits, collecting a tuple of the most recent values from each Observable (in order). If you pass `n` Observables to `combineLatest`, the returned Observable will always emit an ordered tuple of `n` values.

To ensure that the output tuple has a consistent length, `combineLatest` waits for all input Observables to emit at least once before it starts emitting results. This means that if some Observable emits values before other Observables started emitting, all these values but the last will be lost. On the other hand, if some Observable does not emit a value but completes, the resulting Observable will complete simultaneously without emitting anything. Furthermore, if some input Observable does not emit any value and never completes, `combineLatest` will also never emit and never complete.

If at least one Observable was passed to `combineLatest` and all passed Observables emitted, then the resulting Observable will complete when all combined streams complete. So even if some Observable completes, the result of combineLatest will still emit values when the other Observables do. In case of a completed Observable, its value will now remain to be the last emitted value. On the other hand, if any Observable errors, `combineLatest` will also immediately error.

It is possible to change default update/complete strategy behaviour with an optional `strategy` object.
