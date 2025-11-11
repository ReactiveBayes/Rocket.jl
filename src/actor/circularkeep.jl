export CircularKeepActor, circularkeep, getvalues

import DataStructures: CircularBuffer

"""
    CirucalKeepActor{D}() where D

Circual keep actor is similar to keep actor, but uses `CircularBuffer` as a storage. 
It saves all incoming successful `next` events in a `values` circular buffer, throws an ErrorException on `error!` event and does nothing on completion event.

# Examples
```jldoctest
using Rocket

source = from(1:5)
actor  = circularkeep(Int, 3)

subscribe!(source, actor)
show(getvalues(actor))

# output
[3, 4, 5]
```

See also: [`Actor`](@ref), [`keep`](@ref), [`circularkeep`](@ref)
"""
struct CircularKeepActor{T} <: Actor{T}
    values::CircularBuffer{T}

    CircularKeepActor{T}(capacity::Int) where {T} = new{T}(CircularBuffer{T}(capacity))
end

getvalues(actor::CircularKeepActor) = actor.values

on_next!(actor::CircularKeepActor{T}, data::T) where {T} = push!(actor.values, data)
on_error!(actor::CircularKeepActor, err) = error(err)
on_complete!(actor::CircularKeepActor) = begin end

"""
    circularkeep(::Type{T}, capacity::Int) where T

# Arguments
- `::Type{T}`: Type of keep data
- `capacity::Int`: circular buffer capacity

Creation operator for the `CircularKeepActor` actor.

# Examples

```jldoctest
using Rocket

actor = circularkeep(Int, 3)
actor isa CircularKeepActor{Int}

# output
true
```

See also: [`CircularKeepActor`](@ref), [`AbstractActor`](@ref)
"""
circularkeep(::Type{T}, capacity::Int) where {T} = CircularKeepActor{T}(capacity)

# Julia iterable interface

Base.IteratorSize(::Type{<: CircularKeepActor}) = Base.HasLength()
Base.IteratorEltype(::Type{<: CircularKeepActor}) = Base.HasEltype()

Base.IndexStyle(::Type{<: CircularKeepActor}) = Base.IndexLinear()

Base.eltype(::Type{<: CircularKeepActor{T}}) where {T} = T

Base.iterate(actor::CircularKeepActor) = iterate(actor.values)
Base.iterate(actor::CircularKeepActor, state) = iterate(actor.values, state)

Base.size(actor::CircularKeepActor) = (length(actor.values),)
Base.length(actor::CircularKeepActor) = length(actor.values)
Base.getindex(actor::CircularKeepActor, I) = Base.getindex(actor.values, I)

Base.getindex(actor::CircularKeepActor, ::Unrolled.FixedRange{A,B}) where {A,B} =
    getindex(actor, A:B)

Base.firstindex(actor::CircularKeepActor) = firstindex(actor.values)
Base.lastindex(actor::CircularKeepActor) = lastindex(actor.values)
