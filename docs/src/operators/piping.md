# Operators piping

Pipeable operators are special objects, so the could be used like ordinary functions with
`on_call!(operator, source)` - but in practice, there tend to be many of them convolved together, and quickly become unreadable: `on_call!(operator1, on_call!(operator2, on_call!(operator3, source)))`. For that reason, Rx.jl overloads `|>` for operators and Observables that accomplishes the same thing (and also provides some additional checking on the operators itself, yielding more convenient error messages) while being much easier to read:

```julia
source = from([ i for i in 1:100 ]) |>
  filter((d) -> d % 2 === 0) |>
  map(Int, (d) -> d ^ 2) |>
  sum()

subscribe!(source, LoggerActor{Int}())

// Logs
// [LogActor] Data: 171700
// [LogActor] Completed
```

As a stylistic manned, `on_call!(operator, source)` is never used, even if there is only one operator. `source |> operator()` is universally preferred.
