struct VoidTeardown <: Teardown end

as_teardown(::Type{<:VoidTeardown}) = VoidTeardownLogic()
