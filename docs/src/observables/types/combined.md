# [Combined Observable](@id observable_combined)

```@docs
combineLatest
```

## Description

`combineLatest` combines the values from all the Observables passed as arguments. This is done by subscribing to each Observable in order and, whenever any Observable emits, collecting an tuple of the most recent values from each Observable. So if you pass `n` Observables to operator, returned Observable will always emit an tuple of `n` values, in order corresponding to order of passed Observables (value from the first Observable on the first place and so on).

To ensure output tuple has always the same length, combineLatest will actually wait for all input Observables to emit at least once, before it starts emitting results. This means if some Observable emits values before other Observables started emitting, all these values but the last will be lost. On the other hand, if some Observable does not emit a value but completes, resulting Observable will complete at the same moment without emitting anything, since it will be now impossible to include value from completed Observable in resulting tuple. Also, if some input Observable does not emit any value and never completes, combineLatest will also never emit and never complete, since, again, it will wait for all streams to emit some value.

If at least one Observable was passed to combineLatest and all passed Observables emitted something, resulting Observable will complete when all combined streams complete. So even if some Observable completes, result of combineLatest will still emit values when other Observables do. In case of completed Observable, its value from now on will always be the last emitted value. On the other hand, if any Observable errors, combineLatest will error immediately as well.
