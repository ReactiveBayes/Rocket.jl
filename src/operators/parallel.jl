export parallel

"""
    parallel()

Creates a `parallel` operator, which schedules the source observable on a
[`ThreadsScheduler`](@ref). Each emission from the source is then delivered on a separate
thread. This is a shorthand for `schedule_on(ThreadsScheduler())`.

See also: [`ThreadsScheduler`](@ref), [`AbstractScheduler`](@ref)
"""
parallel() = schedule_on(ThreadsScheduler())
