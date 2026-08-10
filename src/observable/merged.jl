export merged

import Base: show

# -------------------- #
# Merge observable     #
# -------------------- #

@subscribable struct MergeObservable{D,S} <: Subscribable{D}
    sources::S
end

function on_subscribe!(observable::MergeObservable{D}, actor) where {D}
    merge_main = __make_merge_main_actor(D, actor, length(observable.sources))

    for (index, source) in enumerate(observable.sources)
        subscription =
            subscribe!(source, __make_merge_child_actor_factory(index, merge_main))
        push!(merge_main.subscriptions, subscription)
        # a source may terminate the stream synchronously during `subscribe!`
        # (e.g. an immediate error); stop subscribing the rest in that case
        if merge_main.isdisposed
            break
        end
    end

    return MergeSubscription(merge_main)
end

# -------------------- #
# Merge main actor     #
# -------------------- #

mutable struct MergeMainActor{D,A} <: Actor{D}
    actor::A
    completion_status::BitArray{1}
    subscriptions::Vector{Teardown}
    isdisposed::Bool
end

__make_merge_main_actor(::Type{D}, actor::A, length::Int) where {D,A} =
    MergeMainActor{D,A}(actor, falses(length), Vector{Teardown}(), false)

# Dispose every child subscription and mark the stream terminated so that no further
# child events are forwarded downstream after an error/completion (issue #70).
function __dispose_merge(actor::MergeMainActor)
    if !actor.isdisposed
        actor.isdisposed = true
        foreach(unsubscribe!, actor.subscriptions)
    end
    return nothing
end

on_next!(actor::MergeMainActor{D}, data::L) where {D,L<:D} = begin
    if !actor.isdisposed
        next!(actor.actor, data)
    end
end
on_error!(actor::MergeMainActor, err) = begin
    if !actor.isdisposed
        __dispose_merge(actor)
        error!(actor.actor, err)
    end
end
on_complete!(actor::MergeMainActor) = begin
    if !actor.isdisposed && all(actor.completion_status)
        __dispose_merge(actor)
        complete!(actor.actor)
    end
end

# -------------------- #
# Merge child actor    #
# -------------------- #

struct MergeChildActor{D,I,A} <: Actor{D}
    main::A
end

on_next!(actor::MergeChildActor{D}, data::D) where {D} = next!(actor.main, data)
on_error!(actor::MergeChildActor, err) = error!(actor.main, err)
on_complete!(actor::MergeChildActor{D,I}) where {D,I} = begin
    actor.main.completion_status[I] = true
    complete!(actor.main)
end

struct MergeChildActorFactory{I,A} <: AbstractActorFactory
    main::A
end

__make_merge_child_actor_factory(index::Int, main::A) where {A} =
    MergeChildActorFactory{index,A}(main)

create_actor(::Type{L}, factory::MergeChildActorFactory{I,A}) where {L,I,A} =
    MergeChildActor{L,I,A}(factory.main)

# -------------------- #
# Merge subscription   #
# -------------------- #

struct MergeSubscription{M} <: Teardown
    main::M
end

as_teardown(::Type{<:MergeSubscription}) = UnsubscribableTeardownLogic()

on_unsubscribe!(subscription::MergeSubscription) = __dispose_merge(subscription.main)

"""
    merged(sources::T) where { T <: Tuple }

Creation operator for the `MergeObservable` with a given `sources` collected in a tuple.
`merge` subscribes to each given input Observable (as arguments), and simply forwards (without doing any transformation) all the values from all the input
Observables to the output Observable. The output Observable only completes once all input Observables have completed.
Any error delivered by an input Observable will be immediately emitted on the output Observable.

# Examples

```jldoctest
using Rocket

observable = merged((from(1:4), of(2.0), from("Hello")))

subscribe!(observable, logger())
;

# output
[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Data: 3
[LogActor] Data: 4
[LogActor] Data: 2.0
[LogActor] Data: H
[LogActor] Data: e
[LogActor] Data: l
[LogActor] Data: l
[LogActor] Data: o
[LogActor] Completed
```

```
using Rocket

subject = Subject(Int, scheduler = AsyncScheduler())

observable = merged((subject, of(2.0), from("Hello")))

actor = sync(logger())

subscribe!(observable, actor)

setTimeout(200) do
    next!(subject, 1)
    complete!(subject)
end

wait(actor)
;

# output
[LogActor] Data: 2.0
[LogActor] Data: H
[LogActor] Data: e
[LogActor] Data: l
[LogActor] Data: l
[LogActor] Data: o
[LogActor] Data: 1
[LogActor] Completed
```

See also: [`Subscribable`](@ref)
"""
merged(sources::T) where {T<:Tuple} =
    MergeObservable{Union{subscribable_extract_type.(sources)...},T}(sources)
merged(sources::T) where {T<:AbstractArray} =
    error("Rocket.merge takes a tuple of sources as an argument, not an array")

Base.show(io::IO, ::MergeObservable{D}) where {D} = print(io, "MergeObservable($D)")
Base.show(io::IO, ::MergeSubscription) = print(io, "MergeSubscription()")
