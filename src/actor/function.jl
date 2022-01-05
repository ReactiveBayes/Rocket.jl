export FunctionActor

"""
    FunctionActor <: Actor{Any}

FunctionActor provides a simple interface to use a single function as a `next!` callback, `error!` callback throws an `ErrorException` and `complete!` callback does nothing.
Should not be used explicitly because it will be created automatically when passing a `Function` object as an actor in `subscribe!` function.

# Examples
```jldoctest
using Rocket

source = from_iterable(1:5)
subscribe!(source, (t) -> println(t))
;

# output
1
2
3
4
5
```

See also: [`subscribe!`](@ref), 
"""
struct FunctionActor{F}
    on_next :: F
end

on_next!(actor::FunctionActor, data) = actor.on_next(data)
on_error!(actor::FunctionActor, err) = error(err)
on_complete!(actor::FunctionActor)   = begin end

subscribe!(subscribable, fn::F)            where { F <: Function } = subscribe!(getscheduler(subscribable), subscribable, FunctionActor{F}(fn))
subscribe!(scheduler, subscribable, fn::F) where { F <: Function } = subscribe!(scheduler, subscribable, FunctionActor{F}(fn))
