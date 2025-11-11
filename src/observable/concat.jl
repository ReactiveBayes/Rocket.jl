export concat

import Base: show

"""
    concat(sources...)
    concat(sources::S) where { S <: Tuple }

Combines multiple Observables to create an Observable which sequentially emits all values from given Observable and then moves on to the next.
All values of each passed Observable merged into a single Observable, in order, in serial fashion.

# Arguments
- `sources`: input sources

# Examples
```jldoctest
using Rocket

source1 = of(1)
source2 = of(2)

subscribe!(concat(source1, source2), logger())
;

# output
[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Completed
```

```
using Rocket

source1 = of(1) |> async()
source2 = of(2)

subscribe!(concat(source1, source2), logger())
;

# output
[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Completed
```
See also: [`Subscribable`](@ref), [`subscribe!`](@ref)
"""
concat() = error("concat operator expects at least one inner observable on input")
concat(args...) = concat(args)
concat(sources::S) where {S<:Tuple} = ConcatObservable{union_type(sources),S}(sources)

##

@subscribable struct ConcatObservable{D,S} <: Subscribable{D}
    sources::S
end

function on_subscribe!(observable::ConcatObservable{D,S}, actor::A) where {D,S,A}
    inner = ConcatInnerActor{D,S,A}(observable.sources, actor)
    subscription = subscribe!(observable.sources[1], inner)
    if get_current_index(inner) === 1
        set_subscription!(inner, subscription)
    end
    return ConcatSubscription(inner)
end

##

mutable struct ConcatInnerActor{D,S,A} <: Actor{D}
    sources::S
    actor::A
    current_index::Int
    subscription::Teardown

    ConcatInnerActor{D,S,A}(sources::S, actor::A) where {D,S,A} = begin
        return new(sources, actor, 1, voidTeardown)
    end
end

get_current_index(actor::ConcatInnerActor) = actor.current_index
set_current_index!(actor::ConcatInnerActor, index) = actor.current_index = index

get_subscription(actor::ConcatInnerActor) = actor.subscription
set_subscription!(actor::ConcatInnerActor, subscription) = actor.subscription = subscription

function on_next!(actor::ConcatInnerActor{D}, data::D) where {D}
    next!(actor.actor, data)
end

function on_error!(actor::ConcatInnerActor, err)
    error!(actor.actor, err)
end

function on_complete!(actor::ConcatInnerActor)
    cindex = get_current_index(actor)
    if cindex === length(actor.sources)
        complete!(actor.actor)
    else
        set_current_index!(actor, cindex + 1)
        subscription = subscribe!(actor.sources[cindex+1], actor)
        if get_current_index(actor) === cindex
            set_subscription!(actor, subscription)
        end
    end
end

##

struct ConcatSubscription{A} <: Teardown
    inner::A
end

as_teardown(::Type{<: ConcatSubscription}) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::ConcatSubscription)
    return unsubscribe!(get_subscription(subscription.inner))
end

Base.show(io::IO, ::ConcatObservable{D}) where {D} = print(io, "ConcatObservable($D)")
Base.show(io::IO, ::ConcatSubscription) = print(io, "ConcatSubscription()")
