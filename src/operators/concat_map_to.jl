export concat_map_to

"""
    switch_map_to(inner_observable)

Creates a `switch_map_to` operator, which returns an observable of values merged together by
joining the passed observable with itself, one after the other, for each value emitted from the source.
Essentially it projects each source value to the same Observable which is merged multiple times in a
serialized fashion on the output Observable.

# Arguments
- `inner_observable`: an Observable to replace each value from the source Observable.

# Producing

Stream of type `<: Subscribable{R}` where R refers to the eltype of `inner_observable`

# Examples
```jldoctest
using Rocket

source = from([ 0, 0, 0 ])
subscribe!(source |> concat_map_to(from([ 1, 2, 3 ])), logger())
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

See also: [`concat_map`](@ref), [`AbstractOperator`](@ref), [`RightTypedOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
concat_map_to(source::S) where S = as_concat_map_to(as_subscribable(S), source)

as_concat_map_to(::InvalidSubscribableTrait,      source)         = throw(InvalidSubscribableTraitUsageError(source))
as_concat_map_to(::SimpleSubscribableTrait{R},    source) where R = concat_map(R, (_) -> source)
as_concat_map_to(::ScheduledSubscribableTrait{R}, source) where R = concat_map(R, (_) -> source)
