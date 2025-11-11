export substitute, SubstituteHandler

import Base: show, push!

mutable struct SubstituteActor{L,R,F,A} <: Actor{L}
    mapFn::F
    actor::A
    pending::Union{Nothing,L}
    current::Union{Nothing,R}
    handler::Any
end


"""
    SubstituteHandler()

handler used to `release!` new values in `substitute` operator.

See also: [`substitute`](@ref)
"""
struct SubstituteHandler
    list::List{SubstituteActor}

    SubstituteHandler() = new(List(SubstituteActor))
end

Base.push!(handler::SubstituteHandler, actor) = pushnode!(handler.list, actor)

release!(handler::SubstituteHandler) = foreach(release!, handler.list)


"""
    substitute(::Type{T}, mapFn::F, handler::SubstituteHandler) where { T, F <: Function }

This operator forces observable to substitute each emmited value with the latest computed value with the corresponding `handler` and `release!` function.
After `release!` on `handler` `substitute` operator computes new value with `mapFn` but does not emit it until next emission from source observable. 
Always calls `mapFn` on first value from source observable.

# Producing

Stream of type `<: Subscribable{T}` 

# Examples
```jldoctest
using Rocket

subject = Subject(Int)

handler = SubstituteHandler()
source  = subject |> substitute(String, i -> string("i = ", i), handler)

subscription = subscribe!(source, logger())

next!(subject, 1)
next!(subject, 2)
next!(subject, 3)

release!(handler)

next!(subject, 4)
next!(subject, 5)
next!(subject, 6)

unsubscribe!(subscription)
;

# output

[LogActor] Data: i = 1
[LogActor] Data: i = 1
[LogActor] Data: i = 1
[LogActor] Data: i = 3
[LogActor] Data: i = 3
[LogActor] Data: i = 3
```

See also: [`SubstituteHandler`](@ref)
"""
substitute(::Type{R}, mapFn::F, handler::SubstituteHandler) where {R,F<:Function} =
    SubstituteOperator{R,F}(mapFn, handler)

struct SubstituteOperator{R,F} <: RightTypedOperator{R}
    mapFn::F
    handler::SubstituteHandler
end

function on_call!(
    ::Type{L},
    ::Type{R},
    operator::SubstituteOperator{R,F},
    source,
) where {L,R,F}
    return proxy(R, source, SubstituteProxy{L,R,F}(operator.mapFn, operator.handler))
end

operator_right(::SubstituteOperator{R}, ::Type{L}) where {L,R} = R

struct SubstituteProxy{L,R,F} <: ActorSourceProxy
    mapFn::F
    handler::SubstituteHandler
end

actor_proxy!(::Type{R}, proxy::SubstituteProxy{L,R,F}, actor::A) where {L,R,F,A} =
    SubstituteActor{L,R,F,A}(proxy.mapFn, actor, nothing, nothing, nothing)

function release!(actor::SubstituteActor)
    if actor.pending !== nothing
        actor.current = actor.mapFn(actor.pending)
    end
    return nothing
end

function on_next!(actor::SubstituteActor{L}, data::L) where {L}
    actor.pending = data
    if actor.current === nothing
        release!(actor)
    end
    if actor.current !== nothing
        next!(actor.actor, actor.current)
    end
end

function on_error!(actor::SubstituteActor, err)
    remove(actor.handler)
    error!(actor.actor, err)
end

function on_complete!(actor::SubstituteActor)
    remove(actor.handler)
    complete!(actor.actor)
end

## 

@subscribable struct SubstituteSource{L,S} <: Subscribable{L}
    source::S
    handler::SubstituteHandler
end

source_proxy!(::Type{R}, proxy::SubstituteProxy{L,R}, source::S) where {L,R,S} =
    SubstituteSource{L,S}(source, proxy.handler)

function on_subscribe!(source::SubstituteSource, actor::SubstituteActor)
    handler = push!(source.handler, actor)
    actor.handler = handler
    subscription = subscribe!(source.source, actor)
    return SubstituteSubscription(handler, subscription)
end

struct SubstituteSubscription{H,S} <: Teardown
    handler::H
    subscription::S
end

as_teardown(::Type{<: SubstituteSubscription}) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::SubstituteSubscription)
    remove(subscription.handler)
    return unsubscribe!(subscription.subscription)
end


Base.show(io::IO, ::SubstituteOperator{R}) where {R} = print(io, "SubstituteOperator($R)")
Base.show(io::IO, ::SubstituteProxy{L,R}) where {L,R} = print(io, "SubstituteProxy($L, $R)")
Base.show(io::IO, ::SubstituteActor{L,R}) where {L,R} =
    print(io, "SubstituteActor($L -> $R)")
Base.show(io::IO, ::SubstituteSource{R}) where {R} = print(io, "SubstituteSource($R)")
Base.show(io::IO, ::SubstituteSubscription) = print(io, "SubstituteSubscription()")
