export LazyObservable, lazy, set!

import Base: |>

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
