struct VoidTeardown <: AbstractTeardown end

as_teardown(::Type{<:VoidTeardown}) = VoidTeardownLogic()
