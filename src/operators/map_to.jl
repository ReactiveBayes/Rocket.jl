export map_to

"""
    map_to(value::T) where T

Creates a map operator, which emits the given constant value on the output Observable every time the source Observable emits a value.

# Arguments
- `value::T`: the constant value to map each source value to

# Producing

Stream of type `<: Subscribable{T}`

# Examples
```jldoctest
using Rocket

source = from([ 1, 2, 3 ])
subscribe!(source |> map_to('a'), logger())
;

# output

[LogActor] Data: a
[LogActor] Data: a
[LogActor] Data: a
[LogActor] Completed
```

See also: [`map`](@ref), [`AbstractOperator`](@ref), [`RightTypedOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
map_to(value::T) where T = map(OpType(T), _ -> value)
