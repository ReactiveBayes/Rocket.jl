export AsapScheduler

import Base: show, similar

"""
    AsapScheduler

`AsapScheduler` executes scheduled actions as soon as possible and does not introduce any additional logic.
`AsapScheduler` is a default scheduler for almost all observables.

See also: [`AsapSchedulerInstance`](@ref)
"""
struct AsapScheduler <: Scheduler end

Base.show(io::IO, ::AsapScheduler) = print(io, "AsapScheduler()")
Base.similar(::AsapScheduler)      = AsapScheduler()

@inline subscribe!(::AsapScheduler, subscribable, actor) = on_subscribe!(subscribable, actor)
@inline unsubscribe!(::AsapScheduler, subscription)      = on_unsubscribe!(subscription)

@inline next!(::AsapScheduler, actor, value) = on_next!(actor, value)
@inline error!(::AsapScheduler, actor, err)  = on_error!(actor, err)
@inline complete!(::AsapScheduler, actor)    = on_complete!(actor)
