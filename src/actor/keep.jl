export KeepActor
export on_next!, on_error!, on_complete!, is_exhausted
export keep

"""
    KeepActor{D}() where D

Keep actor provides a storage actor. It saves all incoming successful `next` events in a `values` array.

See also: [`Actor`](@ref)
"""
mutable struct KeepActor{T} <: Actor{T}
    values :: Vector{T}

    KeepActor{T}() where T = new(Vector{Int}())
end

is_exhausted(actor::KeepActor) = false

on_next!(actor::KeepActor{T}, data::T) where T = push!(actor.values, data)
on_error!(actor::KeepActor, err)               = error(err)
on_complete!(actor::KeepActor)                 = begin end

"""
    keep(::Type{T}) where T

Helper function to create a KeepActor

See also: [`KeepActor`](@ref), [`AbstractActor`](@ref)
"""
keep(::Type{T}) where T = KeepActor{T}()
