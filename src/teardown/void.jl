export VoidTeardown, voidTeardown

import Base: ==

"""
    VoidTeardown()

VoidTeardown object does nothing on unsubscription.
It is usefull for synchronous observables and observables which cannot be cancelled after execution.

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
