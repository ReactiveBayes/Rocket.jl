export KeepActor, keep, getvalues

"""
    KeepActor{D}() where D

Keep actor provides a storage actor. It saves all incoming successful `next` events in a `values` array, throws an ErrorException on `error!` event
and does nothing on completion event.

# Examples
```jldoctest
using Rocket

source = from(1:5)
actor  = keep(Int)

subscribe!(source, actor)
show(getvalues(actor))

# output
[1, 2, 3, 4, 5]
```

See also: [`Actor`](@ref), [`keep`](@ref)
"""
struct KeepActor{T} <: Actor{T}
    values :: Vector{T}

    KeepActor{T}() where T = new(Vector{T}())
end

getvalues(actor::KeepActor) = actor.values

on_next!(actor::KeepActor{T}, data::T) where T = push!(actor.values, data)
on_error!(actor::KeepActor, err)               = error(err)
on_complete!(actor::KeepActor)                 = begin end

"""
    keep(::Type{T}) where T

# Arguments
- `::Type{T}`: Type of keep data

Creation operator for the `KeepActor` actor.

# Examples

```jldoctest
using Rocket

actor = keep(Int)
actor isa KeepActor{Int}

# output
true
```

See also: [`KeepActor`](@ref), [`AbstractActor`](@ref)
"""
keep(::Type{T}) where T = KeepActor{T}()
