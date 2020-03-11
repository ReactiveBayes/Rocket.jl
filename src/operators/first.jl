export FirstNotFoundException, first

import Base: first

struct FirstNotFoundException <: Exception end

"""
    first()

Creates a first operator, which returns an Observable
that emits only the first value emitted by the source Observable.
Sends `FirstNotFoundException` error message if a given source completes without emitting a single value.

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

```jldoctest
using Rocket

source       = completed(Int) |> first()

values      = Int[]
errors      = []
completions = Int[]

subscription = subscribe!(source, lambda(
    on_next     = d -> push!(values, d),
    on_error    = e -> push!(errors, e),
    on_complete = () -> push!(completions, 1)
))

println(isempty(values))
println(isempty(errors))
println(isempty(completions))
println(length(errors))
println(errors[1] isa FirstNotFoundException)
;

# output

true
false
true
1
true
```

See also: [`take`](@ref), [`logger`](@ref)
"""
first() = take(1) + error_if_empty(FirstNotFoundException())
