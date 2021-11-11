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
struct BufferActor{T, R} <: Actor{R}
    values :: R
end

function BufferActor(::Type{T}, size) where T 
    storage = Array{T}(undef, size)
    return BufferActor{T, typeof(storage)}(storage)
end

getvalues(actor::BufferActor) = actor.values

on_next!(actor::BufferActor{T, R}, data::R) where {T, R} = copyto!(actor.values, data)
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
buffer(::Type{T}, size...)     where T = BufferActor(T, size)
buffer(::Type{T}, size::Tuple) where T = BufferActor(T, size)


# Julia iterable interface

Base.IteratorSize(::Type{ <: BufferActor{T, R} })   where { T, R } = Base.IteratorSize(R)
Base.IteratorEltype(::Type{ <: BufferActor{T, R} }) where { T, R } = Base.IteratorEltype(R)

Base.IndexStyle(::Type{ <: BufferActor{T, R} }) where { T, R } = Base.IndexStyle(R)

Base.eltype(::Type{ <: BufferActor{T} }) where T = T

Base.iterate(actor::BufferActor)        = iterate(actor.values)
Base.iterate(actor::BufferActor, state) = iterate(actor.values, state)

Base.collect(actor::BufferActor)     = collect(actor.values)
Base.size(actor::BufferActor)        = size(actor.values)
Base.length(actor::BufferActor)      = length(actor.values)

Base.getindex(actor::BufferActor, I)    = Base.getindex(actor.values, I)
Base.getindex(actor::BufferActor, I...) = Base.getindex(actor.values, I...)

Base.getindex(actor::BufferActor, ::Unrolled.FixedRange{A, B}) where { A, B } = getindex(actor, A:B)

Base.firstindex(actor::BufferActor) = firstindex(actor.values)
Base.lastindex(actor::BufferActor)  = lastindex(actor.values)