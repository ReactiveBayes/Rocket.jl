export LabeledObservable, labeled

import Base: show

"""
    labeled(names::Val, stream)

Creation operator for the `LabeledObservable` that wraps given `stream`, that produces `Tuple` values into a `NamedTuple` with given `names`.

# Arguments
- `names`: a `Val` object that contains a tuple of symbols
- `stream`: an observable that emits a `Tuple`, length of the `Tuple` events must be equal to the length of the `names` argument

# Examples

```jldoctest
using Rocket

source = labeled(Val((:x, :y)), from([ (1, 2), (2, 3), (3, 4) ]))
subscribe!(source, logger())
;

# output

[LogActor] Data: (x = 1, y = 2)
[LogActor] Data: (x = 2, y = 3)
[LogActor] Data: (x = 3, y = 4)
[LogActor] Completed
```

See also: [`ScheduledSubscribable`](@ref), [`subscribe!`](@ref), [`from`](@ref)
"""
labeled(::Val{Names}, stream::S) where {Names,S} = labeled(eltype(S), Val(Names), stream)
labeled(::Type{D}, ::Val{Names}, stream::S) where {D,Names,S} =
    LabeledObservable{NamedTuple{Names,D},S}(stream)

"""
    LabeledObservable{D, S}()

An Observable that emits `NamesTuple` items from a source `Observable` that emits `Tuple` items.

See also: [`Subscribable`](@ref), [`labeled`](@ref)
"""
@subscribable struct LabeledObservable{D,S} <: Subscribable{D}
    stream::S
end

struct LabeledActor{T,N,A} <: Actor{T}
    actor::A
end

@inline on_next!(actor::LabeledActor{T,N}, data::T) where {T,N} =
    next!(actor.actor, NamedTuple{N,T}(data))
@inline on_error!(actor::LabeledActor, err) = error!(actor.actor, err)
@inline on_complete!(actor::LabeledActor) = complete!(actor.actor)

function on_subscribe!(
    observable::LabeledObservable{R},
    actor::A,
) where {N,T,R<:NamedTuple{N,T},A}
    return subscribe!(observable.stream, LabeledActor{T,N,A}(actor))
end

Base.show(io::IO, ::LabeledObservable{D,S}) where {D,S} =
    print(io, "LabeledObservable($D, $S)")
