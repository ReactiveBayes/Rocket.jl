export LazyObservable, lazy, set!

import Base: |>
import DataStructures: CircularBuffer

# TODO: Work in progress

mutable struct LazyObservable{D} <: Subscribable{D}
    observable :: Union{Nothing, Any}
    operators  :: Vector{AbstractOperator}

    LazyObservable{D}() where D = new(nothing, Vector{AbstractOperator}())
end

set!(lazy::LazyObservable{D}, observable::S) where D where S = on_lazy_set!(lazy, as_subscribable(S), observable)

on_lazy_set!(lazy::LazyObservable{D},  ::InvalidSubscribable,   observable) where D           = throw(InvalidSubscribableTraitUsageError(observable))
on_lazy_set!(lazy::LazyObservable{D1}, ::ValidSubscribable{D2}, observable) where D1 where D2 = begin
    source = observable
    for operator in lazy.operators
        source = source |> operator
    end
    lazy.observable = source
end

function on_subscribe!(observable::LazyObservable{D}, actor::A) where { A <: AbstractActor{D} } where D
    return on_lazy_subscribe!(as_subscribable(typeof(observable.observable)), observable, actor)
end

function on_lazy_subscribe!(::ValidSubscribable{D1}, observable::LazyObservable{D2}, actor::A) where { A <: AbstractActor{D2} } where D1 where D2
    return subscribe!(observable.observable, actor)
end

function on_lazy_subscribe!(::InvalidSubscribable, observable::LazyObservable{D}, actor::A) where { A <: AbstractActor{D} } where D
    throw(InvalidSubscribableTraitUsageError(observable.observable))
end

lazy(T = Any) = LazyObservable{T}()

Base.:|>(observable::LazyObservable, operator::O) where { O <: AbstractOperator } = begin
    push!(observable.operators, operator)
    if observable.observable != nothing
        observable.observable = observable.observable |> operator
    end
    return observable
end
