export StorageActor, storage, getvalues

"""
    StorageActor{D}() where D

Storage actor provides an actor that stores a single (last) value passed to the `next!` callback. 
It saves last incoming successful `next` event in the `value` field, throws an ErrorException on `error!` event and does nothing on completion event.
Before any events `value` initialised with `nothing`.

# Examples
```jldoctest
using Rocket

source = from(1:5)
actor  = storage(Int)

subscribe!(source, actor)
show(getvalues(actor))

# output
5
```

See also: [`Actor`](@ref), [`storage`](@ref)
"""
mutable struct StorageActor{T} <: Actor{T}
    value :: Union{Nothing, T}

    StorageActor{T}() where T = new(nothing)
end

getvalues(actor::StorageActor) = actor.value

on_next!(actor::StorageActor{T}, data::T) where T = actor.value = data
on_error!(actor::StorageActor, err)               = error(err)
on_complete!(actor::StorageActor)                 = begin end

"""
    storage(::Type{T}) where T

# Arguments
- `::Type{T}`: Type of storage data

Creation operator for the `StorageActor` actor.

# Examples

```jldoctest
using Rocket

actor = storage(Int)
actor isa StorageActor{Int}

# output
true
```

See also: [`StorageActor`](@ref), [`AbstractActor`](@ref)
"""
storage(::Type{T}) where T = StorageActor{T}()

# Julia iterable interface

Base.IteratorSize(::Type{ <: StorageActor })   = Base.HasLength()
Base.IteratorEltype(::Type{ <: StorageActor }) = Base.HasEltype()

Base.IndexStyle(::Type{ <: StorageActor }) = Base.IndexLinear()

Base.eltype(::Type{ <: StorageActor{T} }) where T = T

Base.iterate(actor::StorageActor{T}) where T        = iterate(actor.value::T)
Base.iterate(actor::StorageActor{T}, state) where T = iterate(actor.value::T, state)

Base.size(actor::StorageActor)        = (length(actor.values), )
Base.length(actor::StorageActor)      = 1