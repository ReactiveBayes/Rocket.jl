# [PendingSubject](@id subject_pending)

```@docs
PendingSubject
PendingSubjectFactory
```

## Description

A variant of `Subject` that only emits a value when it completes. It will emit its latest value to all its observers on completion.
It will reemit its latest value to all new observers on further subscription and then complete. It is not possible to overwrite `last` value after completion.

## Examples

```julia
using Rocket

subject = PendingSubject(Int)

subscription1 = subscribe!(subject, logger("1"))

next!(subject, 1) # Nothing is logged
next!(subject, 2) # Nothing is logged

subscription2 = subscribe!(subject, logger("2"))

next!(subject, 3) # Nothing is logged

complete!(subject)

subscription3 = subscribe!(subject, logger("3"))

[1] Data: 3
[2] Data: 3
[1] Completed
[2] Completed
[3] Data: 3
[3] Completed
```
