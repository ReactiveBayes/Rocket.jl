export switch_map_to

"""
    switch_map_to(inner_observable)

Creates a `switch_map_to` operator, which projects each source value to the same Observable which is
flattened multiple times with `switch_map` in the output Observable.

# Arguments
- `inner_observable`: an Observable to replace each value from the source Observable.

# Producing

Stream of type `<: Subscribable{R}` where R refers to the eltype of `inner_observable`

# Examples
```jldoctest
using Rocket

source = from([ 0, 0, 0 ])
subscribe!(source |> switch_map_to(from([ 1, 2, 3 ])), logger())
;

# output

[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Data: 3
[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Data: 3
[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Data: 3
[LogActor] Completed
```

See also: [`switch_map`](@ref), [`AbstractOperator`](@ref), [`RightTypedOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
switch_map_to(source::S) where S = as_switch_map_to(as_subscribable(S), source)

as_switch_map_to(::InvalidSubscribable,  source)         = throw(InvalidSubscribableTraitUsageError(source))
as_switch_map_to(::ValidSubscribable{R}, source) where R = switch_map(R, (_) -> source)
