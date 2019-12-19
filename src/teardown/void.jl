export VoidTeardown, as_teardown

"""
    VoidTeardown

VoidTeardown object does nothing on unsubscription. It is usefull with synchronous observables.
"""
struct VoidTeardown <: Teardown end

as_teardown(::Type{<:VoidTeardown}) = VoidTeardownLogic()
