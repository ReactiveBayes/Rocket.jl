import Base: map
import Base: show

"""
    map(::Type{R}, mappingFn::F) where { F <: Function }

    Creates a map operator, which applies a given `mappingFn` to each value emmited by the source
    Observable, and emits the resulting values as an Observable. You have to specify output R type after
    `mappingFn` projection.

    # Arguments
    - `::Type{R}`: the type of data of transformed value, may be or may not be the same as source type
    - `mappingFn::Function`: transformation function with `(data::L) -> R` signature, where L is type of data in input source

    # Producing

    Stream of type `<: Subscribable{R}`

    # Examples
    ```jldoctest
    using Rocket

    source = from([ 1, 2, 3 ])
    subscribe!(source |> map(Int, (d) -> d ^ 2), logger())
    ;

    # output

    [LogActor] Data: 1
    [LogActor] Data: 4
    [LogActor] Data: 9
    [LogActor] Completed
    ```

    See also: [`AbstractOperator`](@ref), [`RightTypedOperator`](@ref), [`ProxyObservable`](@ref), [`logger`](@ref)
"""
map(::Type{R}, mappingFn::F) where { R, F <: Function } = MapOperator{R, F}(mappingFn)

struct MapOperator{R, F} <: RightTypedOperator{R}
    mappingFn::F
end

function on_call!(::Type{L}, ::Type{R}, operator::MapOperator{R, F}, source) where { L, R, F }
    return proxy(R, source, MapProxy{L, F}(operator.mappingFn))
end

struct MapProxy{L, F} <: ActorProxy
    mappingFn::F
end

actor_proxy!(proxy::MapProxy{L, F}, actor::A) where { L, A, F } = MapActor{L, A, F}(proxy.mappingFn, actor)

struct MapActor{L, A, F} <: Actor{L}
    mappingFn  :: F
    actor      :: A
end

is_exhausted(actor::MapActor) = is_exhausted(actor.actor)

on_next!(m::MapActor{L},  data::L) where L = next!(m.actor, m.mappingFn(data))
on_error!(m::MapActor, err)                = error!(m.actor, err)
on_complete!(m::MapActor)                  = complete!(m.actor)

Base.show(io::IO, operator::MapOperator{R}) where R   = print(io, "MapOperator( -> $R)")
Base.show(io::IO, proxy::MapProxy{L})       where L   = print(io, "MapProxy($L)")
Base.show(io::IO, actor::MapActor{L})       where L   = print(io, "MapActor($L)")
