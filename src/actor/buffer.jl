export BufferActor, buffer, getvalues

"""
    BufferActor{D}() where D

Buffer actor provides a storage actor. It copies last incoming successful `next` events in a `values` array, throws an ErrorException on `error!` event
and does nothing on completion event. Note: Actor does not check the size of incoming data.

# Examples
```jldoctest
using Rocket

source = of([ 1, 2, 3 ])
actor  = buffer(Int, 3)

subscribe!(source, actor)
show(getvalues(actor))

# output
[1, 2, 3]
```

See also: [`Actor`](@ref), [`buffer`](@ref)
"""
struct BufferActor{T} <: Actor{Vector{T}}
    values :: Vector{T}

    BufferActor{T}(size::Int) where T = new(Vector{T}(undef, size))
end

getvalues(actor::BufferActor) = actor.values

on_next!(actor::BufferActor{T}, data::Vector{T}) where T = copyto!(actor.values, data)
on_error!(actor::BufferActor, err)                       = error(err)
on_complete!(actor::BufferActor)                         = begin end

"""
    buffer(::Type{T}, size::Int) where T

# Arguments
- `::Type{T}`: Type of data in buffer
- `size::Int`: size of buffer

Creation operator for the `BufferActor` actor.

# Examples

```jldoctest
using Rocket

actor = buffer(Int, 3)
actor isa BufferActor{Int}

# output
true
```

See also: [`BufferActor`](@ref), [`AbstractActor`](@ref)
"""
buffer(::Type{T}, size::Int) where T = BufferActor{T}(size)
