export timer

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
- `period`: the period of time between emissions of the subsequent numbers (in milliseconds).

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
    return TimerObservable{delay, 0}()
end

function timer(delay::Int, period::Int)
    @assert delay >= 0 "'delay' argument should be positive"
    @assert period >= 0 "'period' argument should be positive"
    return TimerObservable{delay, period}()
end

"""
    TimerObservable{Delay, Period}()

An Observable that starts emitting after an `Delay` and emits
ever increasing numbers after each `Period` of time thereafter.

# Parameters
- `Delay`: The initial delay time specified as an integer denoting milliseconds to wait before emitting the first value of 0`.
- `Period`: The period of time in milliseconds between emissions of the subsequent numbers.

See also: [`timer`](@ref), [`Subscribable`](@ref)
"""
struct TimerObservable{Delay, Period} <: Subscribable{Int} end

struct TimerSubscription <: Teardown
    timer  :: Timer
end

as_teardown(::Type{<:TimerSubscription}) = UnsubscribableTeardownLogic()

function on_subscribe!(observable::TimerObservable{Delay, Period}, actor) where { Delay, Period }

    timer = Timer(Delay / MILLISECONDS_IN_SECOND, interval = Period / MILLISECONDS_IN_SECOND)

    @async begin
        try
            if isopen(timer)
                if Period === 0
                    wait(timer)
                    next!(actor, 0)
                    complete!(actor)
                else
                    current = 0
                    while true
                        wait(timer)
                        next!(actor, current)
                        current += 1
                    end
                end
            end
        catch err
            if !(err isa EOFError)
                error!(actor, err)
            end
        end
    end

    return TimerSubscription(timer)
end

function on_unsubscribe!(subscription::TimerSubscription)
    close(subscription.timer)
    return nothing
end


Base.:(==)(t1::TimerObservable{D1, P1}, t2::TimerObservable{D2, P2}) where { D1, P1, D2, P2 } = D1 === D2 && P1 === P2

Base.show(io::IO, observable::TimerObservable{Delay, Period}) where { Delay, Period } = print(io, "TimerObservable($Delay, $Period)")
Base.show(io::IO, subscription::TimerSubscription)                                    = print(io, "TimerSubscription()")
