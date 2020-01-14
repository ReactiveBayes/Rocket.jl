export LazyObservable, lazy, set!

import Base: |>

# TODO: Work in progress

mutable struct LazyObservable{D} <: Subscribable{D}
    inner
    lazy

    LazyObservable{D}() where D = begin
        inner = ReplaySubject{Any}(1)
        lazy  = inner |> switchMap(D)
        return new(inner, lazy)
    end
end

set!(lazy::LazyObservable{D}, observable::S) where D where S = on_lazy_set!(lazy, as_subscribable(S), observable)

on_lazy_set!(lazy::LazyObservable{D},  ::InvalidSubscribable,   observable) where D           = throw(InvalidSubscribableTraitUsageError(observable))
on_lazy_set!(lazy::LazyObservable{D1}, ::ValidSubscribable{D2}, observable) where D1 where D2 = begin
    next!(lazy.inner, observable)
end

function on_subscribe!(observable::LazyObservable{D}, actor::A) where { A <: AbstractActor{D} } where D
    return subscribe!(observable.lazy, actor)
end

lazy(T = Any) = LazyObservable{T}()
