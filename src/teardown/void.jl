export VoidTeardown

import Base: ==

"""
    VoidTeardown()

    VoidTeardown object does nothing on unsubscription.
    It is usefull for synchronous observables.

    See also: [`Teardown`](@ref), [`VoidTeardownLogic`](@ref)
"""
struct VoidTeardown <: Teardown end

as_teardown(::Type{<:VoidTeardown}) = VoidTeardownLogic()
