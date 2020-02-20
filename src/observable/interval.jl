export interval

"""
    interval(period::Union{Int, Nothing} = nothing)

    Creation operator for the `TimerObservable`. `interval` returns an Observable that emits an infinite sequence of ascending integers,
    with a constant interval of time of your choosing between those emissions.
    The first emission is not sent immediately, but only after the first period has passed.

    # Arguments
    - `interval`: the interval size in milliseconds

    # Examples

    ```
    using Rocket

    source = interval(50)

    subscription = subscribe!(source, LoggerActor{Int}())
    sleep(0.215)
    unsubscribe!(subscription)
    sleep(0.215)
    subscription = subscribe!(source, LoggerActor{Int}())
    sleep(0.185)
    unsubscribe!(subscription)

    close(source)
    ;

    # output

    [LogActor] Data: 0
    [LogActor] Data: 1
    [LogActor] Data: 2
    [LogActor] Data: 3
    [LogActor] Data: 8
    [LogActor] Data: 9
    [LogActor] Data: 10
    ```

    See also: [`timer`](@ref), [`TimerObservable`](@ref), [`Subscribable`](@ref)
"""
interval(period::Int) = timer(period, period)
