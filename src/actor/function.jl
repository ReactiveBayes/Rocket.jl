
"""
    FunctionActor <: Actor{Any}

FunctionActor provides a simple interface to use a single function as a `next!` callback, `error!` callback throws an `ErrorException` and `complete!` callback does nothing.
Should not be used explicitly because it will be created automatically when passing a `Function` object as an actor in `subscribe!` function.

# Examples
```jldoctest
using Rocket

source = from(1:5)
subscribe!(source, (t) -> println(t))
;

# output
1
2
3
4
5
```

See also: [`Actor`](@ref), [`subscribe!`](@ref)
"""
struct FunctionActor{F} <: Actor{Any}
    on_next :: F
end

next!(actor::FunctionActor, data) = actor.on_next(data)
error!(actor::FunctionActor, err) = error(err)
complete!(actor::FunctionActor)   = begin end

subscribe!(subscribable, fn::F)            where { F <: Function } = subscribe!(subscribable, FunctionActor{F}(fn), getscheduler(subscribable))
subscribe!(subscribable, fn::F, scheduler) where { F <: Function } = subscribe!(subscribable, FunctionActor{F}(fn), scheduler)
