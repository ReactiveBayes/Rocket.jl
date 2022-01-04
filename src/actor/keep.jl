export KeepActor, keep, getvalues

import Base: show

"""
    KeepActor{D}() where D

Keep actor provides a storage actor. It saves all incoming successful `next` events in a `values` array, throws an ErrorException on `error!` event
and does nothing on completion event.

# Examples
```jldoctest
using Rocket

source = from_iterable(1:5)
actor  = keep(Int)

subscribe!(source, actor)
show(getvalues(actor))

# output
[1, 2, 3, 4, 5]
```

See also: [`keep`](@ref)
"""
struct KeepActor{T}
    values :: Vector{T}

    KeepActor{T}() where T = new(Vector{T}())
end

Base.show(io::IO, ::KeepActor{T}) where T = print(io, "KeepActor($T)")

getvalues(actor::KeepActor) = actor.values

on_next!(actor::KeepActor{T}, data::T) where T = push!(actor.values, data)
on_error!(actor::KeepActor, err)               = error(err)
on_complete!(actor::KeepActor)                 = begin end

"""
    keep(::Type{T}) where T

# Arguments
- `::Type{T}`: Type of keep data

Creates `KeepActor` actor.

# Examples

```jldoctest
using Rocket

actor = keep(Int)
actor isa KeepActor{Int}

# output
true
```

See also: [`KeepActor`](@ref), [`Actor`](@ref)
"""
keep(::Type{T}) where T = KeepActor{T}()

# Julia iterable interface

Base.IteratorSize(::Type{ <: KeepActor })   = Base.HasLength()
Base.IteratorEltype(::Type{ <: KeepActor }) = Base.HasEltype()

Base.IndexStyle(::Type{ <: KeepActor }) = Base.IndexLinear()

Base.eltype(::Type{ <: KeepActor{T} }) where T = T

Base.iterate(actor::KeepActor)        = iterate(actor.values)
Base.iterate(actor::KeepActor, state) = iterate(actor.values, state)

Base.size(actor::KeepActor)        = (length(actor.values), )
Base.length(actor::KeepActor)      = length(actor.values)
Base.getindex(actor::KeepActor, I) = Base.getindex(actor.values, I)

Base.getindex(actor::KeepActor, ::Unrolled.FixedRange{A, B}) where { A, B } = getindex(actor, A:B)

Base.firstindex(actor::KeepActor) = firstindex(actor.values)
Base.lastindex(actor::KeepActor)  = lastindex(actor.values)
