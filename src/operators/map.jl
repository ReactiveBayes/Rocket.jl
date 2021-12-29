
import Base: map, show

"""
    map(::OpType{R}, mappingFn::F) where { F }

Creates a map operator, which applies a given `mappingFn` callback to each value emmited by the source
Observable, and emits the resulting values as an Observable. You have to specify output `R` type after
`mappingFn` projection with the `OpType(R)`.

# Arguments
- `::OpType{R}`: the type of data of transformed value, may be or may not be the same as source type
- `mappingFn::Function`: transformation function with `(data::L) -> R` signature, where L is type of data in input source

# Producing

Stream of type `<: Subscribable{R}`

# Examples
```jldoctest
using Rocket

source = from_iterable([ 1, 2, 3 ])
subscribe!(source |> map(OpType(Int), (d) -> d ^ 2), logger())
;

# output

[LogActor] Data: 1
[LogActor] Data: 4
[LogActor] Data: 9
[LogActor] Completed
```

See also: [`AbstractOperator`](@ref), [`RightTypedOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
map(::OpType{R}, mapping::F) where { R, F } = MapOperator{R, F}(mapping)

struct MapOperator{R, F} <: FixedEltypeOperator{R}
    mapping :: F
end

struct MapSubscribable{R, F, S} <: Subscribable{R}
    mapping :: F
    source  :: S
end

struct MapActor{R, F, A} <: Actor{Any}
    mapping :: F
    actor   :: A
end

function on_call!(_, ::Type{R}, operator::MapOperator{R, F}, source::S) where { R, F, S } 
    return MapSubscribable{R, F, S}(operator.mapping, source)
end

function on_subscribe!(source::MapSubscribable{R, F}, actor::A, scheduler) where { R, F, A }
    return on_subscribe!(source.source, MapActor{R, F, A}(source.mapping, actor), scheduler)
end

next!(actor::MapActor{R}, data) where R = next!(actor.actor, convert(R, actor.mapping(data)))
error!(actor::MapActor, err)            = error!(actor.actor, err)
complete!(actor::MapActor)              = complete!(actor.actor)

Base.show(io::IO, ::MapOperator{R})     where R   = print(io, "MapOperator( -> $R)")
Base.show(io::IO, ::MapSubscribable{R}) where R   = print(io, "MapSubscribable( -> $R)")
Base.show(io::IO, ::MapActor{R})        where R   = print(io, "MapActor( -> $R)")
