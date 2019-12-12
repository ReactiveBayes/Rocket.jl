export VoidActor, on_next!, on_error!, on_complete!

struct VoidActor{T} <: Actor{T} end

on_next!(actor::VoidActor{T}, data::T) where T = begin end
on_error!(actor::VoidActor{T}, error)  where T = begin end
on_complete!(actor::VoidActor{T})      where T = begin end
