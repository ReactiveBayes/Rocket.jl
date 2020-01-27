export TimerObservable, on_subscribe!, timer
export TimerSubscription, on_unsubscribe!

"""
    TimerObservable(due_time::Int, period::Union{Int, Nothing} = nothing)

An Observable that starts emitting after an `dueTime` and emits
ever increasing numbers after each `period` of time thereafter.

# Fields
- `due_time`: The initial delay time specified as an integer denoting milliseconds to wait before emitting the first value of 0`.
- `period`: The period of time in milliseconds between emissions of the subsequent numbers.

See also: [`timer`](@ref), [`Subscribable`](@ref)
"""
mutable struct TimerObservable <: Subscribable{Int}
    due_time   :: Int
    period     :: Union{Int, Nothing}

    TimerObservable(due_time::Int, period::Union{Int, Nothing} = nothing) = begin
        @assert due_time >= 0 "due_time argument value should be positive"
        if period !== nothing
            @assert period >= 0 "period argument value should be positive"
        end
        return new(due_time, period)
    end
end

mutable struct TimerSubscription <: Teardown
    is_running :: Bool
    semaphore  :: Base.Semaphore
end

as_teardown(::Type{<:TimerSubscription}) = UnsubscribableTeardownLogic()

function __is_running(subscription::TimerSubscription)
    Base.acquire(subscription.semaphore)
    is_running = subscription.is_running
    Base.release(subscription.semaphore)
    return is_running
end

function on_subscribe!(observable::TimerObservable, actor)
    semaphore = Base.Semaphore(1)

    due_time = observable.due_time
    period   = observable.period

    subscription = TimerSubscription(true, semaphore)

    task = @async begin
        try
            current = 0
            sleep(due_time / MILLISECONDS_IN_SECOND)

            if __is_running(subscription)
                next!(actor, current)
                if period !== nothing
                    sleep(period / MILLISECONDS_IN_SECOND)
                    while __is_running(subscription)
                        current += 1
                        next!(actor, current)
                        sleep(period / MILLISECONDS_IN_SECOND)
                    end
                else
                    complete!(actor)
                end
            end
        catch err
            error!(actor, err)
        end
    end

    return subscription
end

function on_unsubscribe!(subscription::TimerSubscription)
    if __is_running(subscription)
        Base.acquire(subscription.semaphore)
        subscription.is_running = false
        Base.release(subscription.semaphore)
    end
    return nothing
end



"""
    timer(due_time::Int = 0, period = nothing)

Its like `interval`(@ref), but you can specify when should the emissions start.
`timer` returns an Observable that emits an infinite sequence of ascending integers,
with a constant interval of time, period of your choosing between those emissions.
The first emission happens after the specified `due_time`.
If `period` is not specified, the output Observable emits only one value, 0.
Otherwise, it emits an infinite sequence.

# Arguments
- `due_time`: the initial delay time specified as an integer denoting milliseconds to wait before emitting the first value of 0.
- `period`: the period of time between emissions of the subsequent numbers.

# Examples
```
using Rx

source = timer(0, 50)

sleep(0.075)
subscription = subscribe!(source, logger())
sleep(0.105)
unsubscribe!(subscription)

close(source)
;

# output

[LogActor] Data: 2
[LogActor] Data: 3

```

See also: [`interval`](@ref), [`TimerObservable`](@ref), [`subscribe!`](@ref), [`logger`](@ref)
"""
timer(due_time::Int = 0, period::Union{Int, Nothing} = nothing) = TimerObservable(due_time, period)
