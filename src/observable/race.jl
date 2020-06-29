export race

import Base: show

"""
    race(sources...)
    race(sources::S) where { S <: Tuple }

Combines multiple Observables to create an Observable that mirrors the output of the first Observable to emit an item.
Essentially it subscribes to the observable that was the first to start emitting.

# Arguments
- `sources`: input sources

# Examples
```jldoctest
using Rocket

source1 = of(1)
source2 = of(2)

subscribe!(race(source1, source2), logger())
;

# output
[LogActor] Data: 1
[LogActor] Completed
```

```
using Rocket

source1 = of(1) |> async()
source2 = of(2)

subscribe!(race(source1, source2), logger())
;

# output
[LogActor] Data: 2
[LogActor] Completed
```
See also: [`Subscribable`](@ref), [`subscribe!`](@ref)
"""
race()                                = error("race operator expects at least one inner observable on input")
race(args...)                         = race(tuple(args...))
race(sources::S) where { S <: Tuple } = RaceObservable{union_type(sources), S}(sources)

##

struct RaceInnerActor{L, W, I} <: Actor{L}
    wrapper :: W
end

Base.show(io::IO, inner::RaceInnerActor{L, W, I}) where { L, W, I } = print(io, "RaceInnerActor($L, $I)")

on_next!(actor::RaceInnerActor{L, W, I}, data::L) where { L, W, I } = next_received!(actor.wrapper, data, Val{I}())
on_error!(actor::RaceInnerActor{L, W, I}, err)    where { L, W, I } = error_received!(actor.wrapper, err, Val{I}())
on_complete!(actor::RaceInnerActor{L, W, I})      where { L, W, I } = complete_received!(actor.wrapper, Val{I}())

##

mutable struct RaceActorWrapperProps
    first_emmited_index :: Union{Nothing, Int}
end

struct RaceActorWrapper{A}
    actor         :: A
    subscriptions :: Vector{Teardown}
    props         :: RaceActorWrapperProps

    RaceActorWrapper{A}(actor::A) where A = new(actor, Vector{Teardown}(), RaceActorWrapperProps(nothing))
end

has_emmited(wrapper::RaceActorWrapper)                     = get_first_emmited_index(wrapper) !== nothing
get_first_emmited_index(wrapper::RaceActorWrapper)         = wrapper.props.first_emmited_index
set_first_emmited_index!(wrapper::RaceActorWrapper, index) = wrapper.props.first_emmited_index = index

function next_received!(wrapper::RaceActorWrapper, data, index::Val{I}) where I
    first = get_first_emmited_index(wrapper)
    if first === nothing
        set_first_emmited_index!(wrapper, I)
        dispose_except(wrapper, index)
        next_received!(wrapper, data, index)
    elseif first === I
        next!(wrapper.actor, data)
    end
end

function error_received!(wrapper::RaceActorWrapper, err, index::Val{I}) where I
    first = get_first_emmited_index(wrapper)
    if first === nothing
        set_first_emmited_index!(wrapper, I)
        error_received!(wrapper, err, index)
    elseif first === I
        dispose(wrapper)
        error!(wrapper.actor, err)
    end
end

function complete_received!(wrapper::RaceActorWrapper, index::Val{I}) where I
    first = get_first_emmited_index(wrapper)
    if first === nothing
        set_first_emmited_index!(wrapper, I)
        complete_received!(wrapper, index)
    elseif first === I
        dispose(wrapper)
        complete!(wrapper.actor)
    end
end

dispose(wrapper::RaceActorWrapper) = foreach(s -> unsubscribe!(s), wrapper.subscriptions)

function dispose_except(wrapper::RaceActorWrapper, index::Val{I}) where I
    for (i, subscription) in enumerate(wrapper.subscriptions)
        if i !== I
            unsubscribe!(subscription)
        end
    end
end

##

struct RaceObservable{T, S} <: Subscribable{T}
    sources :: S
end

function on_subscribe!(observable::RaceObservable, actor::A) where { A }
    wrapper = RaceActorWrapper{A}(actor)
    for (index, source) in enumerate(observable.sources)
        push!(wrapper.subscriptions, subscribe!(source, RaceInnerActor{eltype(source), typeof(wrapper), index}(wrapper)))
        if has_emmited(wrapper)
            break
        end
    end
    return RaceSubscription(wrapper)
end

##

struct RaceSubscription{W} <: Teardown
    wrapper :: W
end

as_teardown(::Type{ <: RaceSubscription }) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::RaceSubscription)
    dispose(subscription.wrapper)
    return nothing
end

Base.show(io::IO, ::RaceObservable{D}) where D  = print(io, "RaceObservable($D)")
Base.show(io::IO, ::RaceSubscription)           = print(io, "RaceSubscription()")
