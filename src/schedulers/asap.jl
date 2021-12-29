export AsapScheduler

import Base: show, similar

"""
    AsapScheduler

`AsapScheduler` executes scheduled actions as soon as possible and does not introduce any additional logic.
`AsapScheduler` is a default scheduler for almost all observables.

See also: [`AsapSchedulerInstance`](@ref)
"""
struct AsapScheduler <: AbstractScheduler end

Base.show(io::IO, ::AsapScheduler) = print(io, "AsapScheduler()")

Base.similar(::AsapScheduler) = AsapScheduler()

struct AsapSchedulerInstance end

makeinstance(_, ::AsapScheduler)         = AsapSchedulerInstance()
instancetype(_, ::Type{ AsapScheduler }) = AsapSchedulerInstance

next!(actor, value, ::AsapScheduler) = next!(actor, value)
error!(actor, err, ::AsapScheduler)  = error!(actor, err)
complete!(actor, ::AsapScheduler)    = complete!(actor)
