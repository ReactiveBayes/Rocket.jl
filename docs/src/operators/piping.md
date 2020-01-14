# Operators piping

Pipeable operators are special objects that can be used like ordinary functions with
`on_call!(operator, source)`. In practice however they tend to accumulate and quickly grow unreadable: `on_call!(operator1, on_call!(operator2, on_call!(operator3, source)))`. Therefore, Rx.jl overloads `|>` for operators and Observables:

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

For stylistic reasons, `on_call!(operator, source)` is never used in practice - even if there is only one operator. Instead, `source |> operator()` is generally preferred.
