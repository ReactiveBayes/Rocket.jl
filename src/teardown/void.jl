export VoidTeardown, voidTeardown

import Base: ==

"""
    VoidTeardown()

A `VoidTeardown` object does nothing on unsubscription.
It is useful for synchronous observables and for observables that cannot be cancelled after execution.

See also: [`Teardown`](@ref), [`VoidTeardownLogic`](@ref)
"""
struct VoidTeardown <: Teardown end

as_teardown(::Type{<:VoidTeardown}) = VoidTeardownLogic()

"""
    voidTeardown

An instance of VoidTeardown singleton object.

See also: [`VoidTeardown`](@ref)
"""
const voidTeardown = VoidTeardown()
