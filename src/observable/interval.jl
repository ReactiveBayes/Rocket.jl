export interval

"""
    interval(period::Union{Int, Nothing} = nothing)

interval returns an Observable that emits an infinite sequence of ascending integers,
with a constant interval of time of your choosing between those emissions.
The first emission is not sent immediately, but only after the first period has passed.
Note that you have to `close` timer observable when you do not need it.

See also: [`timer`](@ref), ['TimerObservable'](@ref), ['Subscribable'](@ref)
"""
interval(period::Int) = timer(period, period)
