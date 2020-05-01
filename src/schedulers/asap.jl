
"""
    AsapScheduler

`AsapScheduler` executes scheduled actions as soon as possible and does not introduce any additional logic.
`AsapScheduler` is a default scheduler for alsmost all observables.

See also: [`getscheduler`](@ref), [`scheduled_subscription!`](@ref), [`scheduled_next!`](@ref), [`scheduled_error!`](@ref), [`scheduled_complete!`](@ref)
"""
struct AsapScheduler end

makeinstance(::Type, ::Nothing)       = AsapScheduler()
makeinstance(::Type, ::AsapScheduler) = AsapScheduler()

instancetype(::Type, ::Type{<:Nothing})       = AsapScheduler
instancetype(::Type, ::Type{<:AsapScheduler}) = AsapScheduler

scheduled_subscription!(source, actor, instance::AsapScheduler) = on_subscribe!(source, actor, instance)

scheduled_next!(actor, value, ::AsapScheduler) = on_next!(actor, value)
scheduled_error!(actor, err, ::AsapScheduler)  = on_error!(actor, err)
scheduled_complete!(actor, ::AsapScheduler)    = on_complete!(actor)
