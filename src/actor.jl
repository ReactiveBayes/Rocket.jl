export Actor
export next!, error!, complete!
export AbstractActorFactory, create_actor

import Base: eltype
  
abstract type Actor{T} end

Base.eltype(::Actor{T})            where T = T
Base.eltype(::Type{ <: Actor{T} }) where T = T

"""
    next!(actor, data)
    next!(actor, data, scheduler)

Delivers a "next" event to an actor. Takes optional `scheduler` object to schedule execution of data delivery.

See also: [`Actor`](@ref), [`error!`](@ref), [`complete!`](@ref)
"""
function next! end

"""
    error!(actor, err)
    error!(actor, err, scheduler)

Delivers an "error" event to an actor. Takes optional `scheduler` object to schedule execution of error delivery.

See also: [`Actor`](@ref), [`next!`](@ref), [`complete!`](@ref)
"""
function error! end

"""
    complete!(actor)
    complete!(actor, scheduler)

Delivers a "complete" event to an actor. Takes optional `scheduler` object to schedule execution of complete event delivery.

See also: [`Actor`](@ref), [`next!`](@ref), [`error!`](@ref)
"""
function complete! end

next!(_)  = throw(MissingDataArgumentInNextCall())
error!(_) = throw(MissingErrorArgumentInErrorCall())

# -------------------------------- #
# Actor factory                    #
# -------------------------------- #

"""
Abstract type for actor factories. Actor factory is particularly useful to create an actor based on the `eltype` of a subscribable.
`AbstractActorFactory` creates an actor with `create_actor(eltype(subscribable), factory)` function during execution on every `subscribe!` function call.

See also: [`Actor`](@ref)
"""
abstract type AbstractActorFactory end

"""
    create_actor(::Type{L}, factory::F) where { L, F <: AbstractActorFactory }

Creates an actor based on type `L` and factory `F`. Should be implemented explicitly for any `AbstractActorFactory` object

See also: [`AbstractActorFactory`](@ref)
"""
function create_actor end

# -------------------------------- #
# Errors                           #
# -------------------------------- #

import Base: showerror

"""
Missing `data` argument in `next!(actor, data)` function call

See also: [`next!`](@ref)
"""
struct MissingDataArgumentInNextCall end

Base.showerror(io::IO, ::MissingDataArgumentInNextCall) = print(io, "Missing `data` argument in `next!(actor, data)` function call")

"""
Missing `error` argument in `error!(actor, error)` function call

See also: [`error!`](@ref)
"""
struct MissingErrorArgumentInErrorCall end

Base.showerror(io::IO, ::MissingErrorArgumentInErrorCall) = print(io, "Missing `error` argument in `error!(actor, error)` function call")
