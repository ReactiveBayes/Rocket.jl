export timer, TimerObservable

import Base: ==
import Base: show

"""
    timer(delay::Int)
    timer(delay::Int, period::Int)

Creation operator for the `TimerObservable`. Its like `interval`(@ref), but you can specify when should the emissions start.
`timer` returns an Observable that emits an infinite sequence of ascending integers,
with a constant interval of time, period of your choosing between those emissions.
The first emission happens after the specified `delay`.
If `period` is not specified, the output Observable emits only one value, 0.
Otherwise, it emits an infinite sequence.

# Arguments
- `delay`: the initial delay time specified as an integer denoting milliseconds to wait before emitting the first value of 0.
- `period`: the minimum period of time between emissions of the subsequent numbers (in milliseconds).

# Examples
```
using Rocket

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
function timer(delay::Int)
    @assert delay >= 0 "'delay' argument should be positive"
    return TimerObservable(delay, 0)
end

function timer(delay::Int, period::Int)
    @assert delay >= 0 "'delay' argument should be positive"
    @assert period >= 0 "'period' argument should be positive"
    return TimerObservable(delay, period)
end

"""
    TimerObservable

An Observable that starts emitting after an `delay` and emits
ever increasing numbers after each `period` of time thereafter.

# Parameters
- `delay`: The initial delay time specified as an integer denoting milliseconds to wait before emitting the first value of 0`.
- `period`: The minimum period of time in milliseconds between emissions of the subsequent numbers.

See also: [`timer`](@ref), [`Subscribable`](@ref)
"""
struct TimerObservable <: Subscribable{Int} 
    delay  :: Int
    period :: Int
end

getdelay_ms(observable::TimerObservable)  = observable.delay
getperiod_ms(observable::TimerObservable) = observable.period

getdelay_sec(observable::TimerObservable)  = getdelay_ms(observable) / MILLISECONDS_IN_SECOND
getperiod_sec(observable::TimerObservable) = getperiod_ms(observable) / MILLISECONDS_IN_SECOND

struct TimerSubscription <: Teardown
    timer  :: Timer
end

as_teardown(::Type{ <: TimerSubscription }) = UnsubscribableTeardownLogic()

mutable struct TimerActor{A} <: Actor{ Nothing }
    actor   :: A
    once    :: Bool
    counter :: Int
end

TimerActor(actor::A, once::Bool) where A = TimerActor{A}(actor, once, 0)

getcounter(actor::TimerActor) = actor.counter
itcounter!(actor::TimerActor) = actor.counter = actor.counter + 1

isonce(actor::TimerActor) = actor.once

function on_next!(actor::TimerActor, ::Nothing)
    next!(actor.actor, getcounter(actor))
    if isonce(actor)
        complete!(actor)
    else 
        itcounter!(actor)
    end
end

on_error!(actor::TimerActor, err) = error!(actor.actor, err)
on_complete!(actor::TimerActor)   = complete!(actor.actor)

function on_subscribe!(observable::TimerObservable, actor)

    tactor   = TimerActor(actor, getperiod_ms(observable) === 0)

    callback = let tactor = tactor
        (timer) -> begin 
            try 
                next!(tactor, nothing)
            catch err
                error!(tactor, err)
                close(timer)
            end
        end
    end

    timer = Timer(callback, getdelay_sec(observable), interval = getperiod_sec(observable))

    return TimerSubscription(timer)
end

function on_unsubscribe!(subscription::TimerSubscription)
    close(subscription.timer)
    return nothing
end


Base.:(==)(t1::TimerObservable, t2::TimerObservable) = getdelay_ms(t1) === getdelay_ms(t1) && getperiod_ms(t1) === getperiod_ms(t2)

Base.show(io::IO, observable::TimerObservable)   = print(io, "TimerObservable($(getdelay_ms(observable)), $(getperiod_ms(observable)))")
Base.show(io::IO, ::TimerSubscription)           = print(io, "TimerSubscription()")
