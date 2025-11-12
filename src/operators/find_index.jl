export find_index

import Base: show

"""
    find_index(conditionFn::F) where { F <: Function }

Creates a find operator, which emits only the index of the first value emitted by the source Observable that meets some condition.
Indices are 1-based.

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream

# Arguments
- `conditionFn::F`: condition function with `(data::T) -> Bool` signature

# Examples
```jldoctest
using Rocket

source = from([ 0, 1, 2, 3, 4, 5, 6, 7, 8 ])
subscribe!(source |> find_index((d) -> d !== 0 && d % 2 == 0), logger())
;

# output

[LogActor] Data: 3
[LogActor] Completed
```

See also: [`find`](@ref), [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
find_index(conditionFn::F) where {F<:Function} =
    enumerate() + find(d -> conditionFn(d[2])) + map(Int, d -> d[1])
