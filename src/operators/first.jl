export first

import Base: first

"""
    first()

Creates a first operator, which returns an Observable
that emits only the first value emitted by the source Observable.

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream

# Examples
```jldoctest
using Rocket

source = from([ i for i in 1:100 ])
actor  = keep(Int)
subscription = subscribe!(source |> first(), actor)
println(actor.values)
;

# output

[1]
```

See also: [`take`](@ref), [`logger`](@ref)
"""
first() = take(1)
