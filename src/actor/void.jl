export VoidActor, void

"""
    VoidActor{D}() where D

Void actor does nothing with input data, error and complete events, can be useful for debugging (e.g. to start side-effects with [`tap`](@ref) operator)

# Examples

```jldoctest
using Rx

source = from([ 0, 1, 2 ])
actor  = VoidActor{Int}()

subscribe!(source, actor)
;

# output

```

See also: [`Actor`](@ref), [`void`](@ref), [`tap`](@ref)
"""
struct VoidActor{T} <: Actor{T} end

is_exhausted(actor::VoidActor) = false

on_next!(actor::VoidActor{T}, data::T) where T = begin end
on_error!(actor::VoidActor, err)               = begin end
on_complete!(actor::VoidActor)                 = begin end

struct VoidActorFactory <: AbstractActorFactory end

create_actor(::Type{L}, factory::VoidActorFactory) where L = VoidActor{L}()

"""
    void()
    void(::Type{T}) where T

Creation operator for the `VoidActor` actor.

# Examples

```jldoctest
using Rx

actor = void(Int)
actor isa VoidActor{Int}

# output
true

```

See also: [`VoidActor`](@ref), [`AbstractActor`](@ref)
"""
void()                  = VoidActorFactory()
void(::Type{T}) where T = VoidActor{T}()
