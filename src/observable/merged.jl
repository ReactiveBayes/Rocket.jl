export merged

import Base: show

# -------------------- #
# Merge observable     #
# -------------------- #

struct MergeObservable{D, S} <: Subscribable{D}
    sources :: S
end

function on_subscribe!(observable::MergeObservable{D}, actor) where D
    merge_main    = __make_merge_main_actor(D, actor, length(observable.sources))

    subscriptions = map(enumerate(observable.sources)) do (index, source)
        return subscribe!(source, __make_merge_child_actor_factory(index, merge_main))
    end

    return MergeSubscription(subscriptions)
end

# -------------------- #
# Merge main actor     #
# -------------------- #

struct MergeMainActor{D, A} <: Actor{D}
    actor             :: A
    completion_status :: BitArray{1}
end

__make_merge_main_actor(::Type{D}, actor::A, length::Int) where { D, A } = MergeMainActor{D, A}(actor, falses(length))

on_next!(actor::MergeMainActor{D}, data::L) where { D, L <: D } = next!(actor.actor, data)
on_error!(actor::MergeMainActor, err)                           = error!(actor.actor, err)
on_complete!(actor::MergeMainActor)                             = begin
    if all(actor.completion_status)
        complete!(actor.actor)
    end
end

# -------------------- #
# Merge child actor    #
# -------------------- #

struct MergeChildActor{D, I, A} <: Actor{D}
    main :: A
end

on_next!(actor::MergeChildActor{D}, data::D) where D     = next!(actor.main, data)
on_error!(actor::MergeChildActor, err)                   = error!(actor.main, err)
on_complete!(actor::MergeChildActor{D, I}) where { D, I } = begin
    actor.main.completion_status[I] = true
    complete!(actor.main)
end

struct MergeChildActorFactory{I, A} <: AbstractActorFactory 
    main :: A
end

__make_merge_child_actor_factory(index::Int, main::A) where A = MergeChildActorFactory{index, A}(main)

create_actor(::Type{L}, factory::MergeChildActorFactory{I, A}) where { L, I, A } = MergeChildActor{L, I, A}(factory.main)

# -------------------- #
# Merge subscription   #
# -------------------- #

struct MergeSubscription{S} <: Teardown
    subscriptions :: S
end

as_teardown(::Type{<:MergeSubscription}) = UnsubscribableTeardownLogic()

on_unsubscribe!(subscription::MergeSubscription) = foreach(s -> unsubscribe!(s), subscription.subscriptions)

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

    ```jldoctest
    using Rocket

    observable = merged((timer(100, 1), of(2.0), from("Hello"))) |> take(10)

    subscribe!(observable, logger())
    ;

    # output
    [LogActor] Data: 2.0
    [LogActor] Data: H
    [LogActor] Data: e
    [LogActor] Data: l
    [LogActor] Data: l
    [LogActor] Data: o
    [LogActor] Data: 0
    [LogActor] Data: 1
    [LogActor] Data: 2
    [LogActor] Data: 3
    [LogActor] Completed
    ```

    See also: [`Subscribable`](@ref)
"""
merged(sources::T) where { T <: Tuple }         = MergeObservable{ Union{ subscribable_extract_type.(sources)... }, T }(sources)
merged(sources::T) where { T <: AbstractArray } = error("Rocket.merge takes a tuple of sources as an argument, not an array")

Base.show(io::IO, observable::MergeObservable{D}) where D = print(io, "MergeObservable($D)")
Base.show(io::IO, observable::MergeSubscription)          = print(io, "MergeSubscription()")
