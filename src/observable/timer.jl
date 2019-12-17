export TimerObservable, on_subscribe!, timer
export close

import Base: close

const MILLISECONDS_IN_SECOND = 1000.0::Float64

"""
    TimerObservable <: Subscribable{Int}

An Observable that starts emitting after an `dueTime` and emits
ever increasing numbers after each `period` of time thereafter.

# Fields
- `due_time`: The initial delay time specified as an integer denoting milliseconds to wait before emitting the first value of 0`.
- `period`: The period of time in milliseconds between emissions of the subsequent numbers.

"""
mutable struct TimerObservable <: Subscribable{Int}
    due_time   :: Int
    period     :: Union{Int, Nothing}
    current    :: Int
    subject    :: Subject{Int}
    is_stopped :: Bool

    TimerObservable(due_time::Int, period::Union{Int, Nothing} = nothing) = begin
        subject = Subject{Int}()

        timer = new(due_time, period, 0, subject, false)

        task = @async begin
            sleep(due_time / MILLISECONDS_IN_SECOND)
            if isperiodic(timer)
                while !timer.is_stopped
                    next!(timer.subject, timer.current)
                    timer.current += 1
                    sleep(period / MILLISECONDS_IN_SECOND)
                end
            else
                next!(timer.subject, 0)
                complete!(timer.subject)
            end
        end

        bind(timer.subject.channel, task)

        timer
    end
end

isperiodic(observable::TimerObservable) = observable.period != nothing

function on_subscribe!(observable::TimerObservable, actor::A) where { A <: AbstractActor{Int} }
    return chain(subscribe!(observable.subject, actor))
end

"""
    timer(due_time::Int = 0, period = nothing)

`timer` returns an Observable that emits an infinite sequence of ascending integers,
with a constant interval of time, period of your choosing between those emissions.
The first emission happens after the specified `due_time`.
If `period` is not specified, the output Observable emits only one value, 0.
Otherwise, it emits an infinite sequence.
Note that you have to `close` timer observable when you do not need it.
"""
timer(due_time::Int = 0, period::Union{Int, Nothing} = nothing) = TimerObservable(due_time, period)

function close(observable::TimerObservable)
    observable.is_stopped = true
    close(observable.subject)
end
