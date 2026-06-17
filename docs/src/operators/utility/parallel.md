# [Parallel Operator](@id operator_parallel)

```@docs
parallel
```

## Description

The `parallel` operator schedules the source observable on a [`ThreadsScheduler`](@ref Rocket.ThreadsScheduler), so each emission is delivered on a separate thread. It is a shorthand for scheduling on threads and is useful when you want to move work off the current thread.

## See also

[Operators](@ref what_are_operators), [`ThreadsScheduler`](@ref Rocket.ThreadsScheduler)
