export find

import Base: show

"""
    find(conditionFn::F) where { F <: Function }

Creates a find operator, which emits only the first value emitted by the source Observable that meets some condition.

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream

# Arguments
- `conditionFn::F`: condition function with `(data::T) -> Bool` signature

# Examples
```jldoctest
using Rocket

source = from([ 1, 2, 3, 4, 5, 6, 7, 8 ])
subscribe!(source |> find((d) -> d % 2 == 0), logger())
;

# output

[LogActor] Data: 2
[LogActor] Completed
```

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
find(conditionFn::F) where { F <: Function } = filter(conditionFn) + take(1)
