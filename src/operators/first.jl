export first, FirstNotFoundException

import Base: first

struct FirstNotFoundException <: Exception end

"""
    first(; default = nothing)

Creates a first operator, which returns an Observable
that emits only the first value emitted by the source Observable.
Sends `FirstNotFoundException` error message if a given source completes without emitting a single value.

# Arguments
- `default`: an optional default value to provide if no values were emitted

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream

# Examples
```jldoctest
using Rocket

source       = from(1:100)
subscription = subscribe!(source |> first(), logger())
;

# output

[LogActor] Data: 1
[LogActor] Completed
```

See also: [`take`](@ref), [`logger`](@ref)
"""
first(; default = nothing) = default === nothing ? take(1) + error_if_empty(FirstNotFoundException()) : take(1) + default_if_empty(default)
