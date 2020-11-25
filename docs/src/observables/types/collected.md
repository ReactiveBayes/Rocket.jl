# [Collected Observable](@id observable_collected)

```@docs
collectLatest
```

## Description

`collectLatest` collects the values from all Observables in its vector argument. This is done by subscribing to each Observable in order and, whenever an Observable emits, collecting a vector of the most recent values from each Observable (in order). If you pass `n` Observables to `collectLatest`, the returned Observable will always emit an ordered vector of `n` values.

To ensure that the output vector has a consistent length, `collectLatest` waits for all input Observables to emit at least once before it starts emitting results. This means that if some Observable emits values before other Observables started emitting, all these values but the last will be lost. On the other hand, if some Observable does not emit a value but completes, the resulting Observable will complete simultaneously without emitting anything. Furthermore, if some input Observable does not emit any value and never completes, `collectLatest` will also never emit and never complete.

If at least one Observable was passed to `collectLatest` and all passed Observables emitted, then the resulting Observable will complete when all combined streams complete. So even if some Observable completes, the result of `collectLatest` will still emit values when the other Observables do. In case of a completed Observable, its value will now remain to be the last emitted value. On the other hand, if any Observable errors, `collectLatest` will also immediately error.


