export LazyObservable, LazyReplayObservable, lazy, lazy_replay, set!

import Base: |>
import DataStructures: CircularBuffer

# TODO: Work in progress

mutable struct LazyObservable{D} <: Subscribable{D}
    observable :: Any
    operators  :: Vector{AbstractOperator}

    LazyObservable{D}() where D = begin
        lazy = new()

        lazy.operators = Vector{AbstractOperator}()

        return lazy
    end
end

set!(lazy::LazyObservable{D}, observable::S) where D where S = on_lazy_set!(lazy, as_subscribable(S), observable)

on_lazy_set!(lazy::LazyObservable{D},  ::InvalidSubscribable,   observable) where D           = throw(InvalidSubscribableTraitUsageError(observable))
on_lazy_set!(lazy::LazyObservable{D1}, ::ValidSubscribable{D2}, observable) where D1 where D2 = lazy.observable = observable

function on_subscribe!(observable::LazyObservable{D}, actor::A) where { A <: AbstractActor{D} } where D
    return on_lazy_subscribe!(as_subscribable(typeof(observable.observable)), observable, actor)
end

function on_lazy_subscribe!(::ValidSubscribable{D1}, observable::LazyObservable{D2}, actor::A) where { A <: AbstractActor{D2} } where D1 where D2
    source = observable.observable
    for operator in observable.operators
        source = source |> operator
    end
    return subscribe!(source, actor)
end

function on_lazy_subscribe!(::InvalidSubscribable, observable::LazyObservable{D}, actor::A) where { A <: AbstractActor{D} } where D
    throw(InvalidSubscribableTraitUsageError(observable.observable))
end

lazy(T = Any) = LazyObservable{T}()

Base.:|>(source::LazyObservable, operator::O) where { O <: AbstractOperator } = begin
    push!(source.operators, operator)
    return source
end

## Lazy replay ###

struct LazyReplayActor{D} <: NextActor{D}
    lazy_replay_observable
end

on_next!(actor::LazyReplayActor{D}, data::D) where D = push!(actor.lazy_replay_observable.cb, data)

mutable struct LazyReplayObservable{D} <: Subscribable{D}
    cb           :: CircularBuffer{D}
    observable   :: LazyObservable{D}
    subscription :: Union{Nothing, Teardown}

    LazyReplayObservable{D}(count::Int, observable::LazyObservable{D}) where D = new(CircularBuffer{D}(count), observable, nothing)
end

set!(lazy::LazyReplayObservable{D}, observable::S) where D where S = on_lazy_replay_set!(lazy, as_subscribable(S), observable)

on_lazy_replay_set!(lazy::LazyReplayObservable{D},  ::InvalidSubscribable,   observable) where D           = throw(InvalidSubscribableTraitUsageError(observable))
on_lazy_replay_set!(lazy::LazyReplayObservable{D1}, ::ValidSubscribable{D2}, observable) where D1 where D2 = begin
    try
        if lazy.subscription != nothing
            unsubscribe!(lazy.subscription)
        end
        @async begin
            lazy.subscription = subscribe!(observable, LazyReplayActor{D1}(lazy))
        end
        set!(lazy.observable, observable)
    catch e
        println(e)
    end
end

function on_subscribe!(observable::LazyReplayObservable, actor)
    for v in observable.cb
        next!(actor, v)
    end
    return subscribe!(observable.observable, actor)
end

lazy_replay(count::Int, T = Any) = LazyReplayObservable{T}(count, LazyObservable{T}())

Base.:|>(source::LazyReplayObservable, operator::O) where { O <: AbstractOperator } = begin
    source.observable = source.observable |> operator
    return source
end
