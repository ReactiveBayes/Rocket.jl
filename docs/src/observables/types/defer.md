# [Defer Observable](@id observable_defer)

```@docs
defer
```

## Description

`defer` allows you to create the Observable only when the Actor subscribes, and create a fresh Observable for each Actor. It waits until an Actor subscribes to it, and then it generates an Observable, typically with an Observable factory function. It does this afresh for each subscriber, so although each subscriber may think it is subscribing to the same Observable, in fact each subscriber gets its own individual Observable.
