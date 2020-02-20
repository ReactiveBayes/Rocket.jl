export FunctionActor
export subscribe!

"""
    FunctionActor{D} <: Actor{D}

FunctionActor provides a simple interface to use a single function as a `next!` callback.
`error!` callback throws an `ErrorException` and `complete!` is empty.
Should not be used explicitly because it will be created automatically when passing a `Function` object as an actor in
`subscribe!` function.

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
struct FunctionActor{D, F} <: Actor{D}
    on_next :: F
end

on_next!(actor::FunctionActor{D}, data::D) where D = actor.on_next(data)
on_error!(actor::FunctionActor, err)               = error(err)
on_complete!(actor::FunctionActor)                 = begin end

struct FunctionActorFactory{F} <: AbstractActorFactory
    on_next :: F
end

create_actor(::Type{L}, factory::FunctionActorFactory{F}) where { L, F } = FunctionActor{L, F}(factory.on_next)

function subscribe!(source, fn::F) where { F <: Function }
    return subscribe!(source, FunctionActorFactory{F}(fn))
end
