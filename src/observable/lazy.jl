export LazyObservable, lazy, set!

import Base: |>

mutable struct LazyObservable{D} <: Subscribable{D}
    inner :: ReplaySubject{Any}

    LazyObservable{D}() where D = new(ReplaySubject{Any}(1))
end

set!(lazy::LazyObservable{D}, observable::S) where D where S = on_lazy_set!(lazy, as_subscribable(S), observable)

on_lazy_set!(lazy::LazyObservable{D},  ::InvalidSubscribable,   observable) where D           = throw(InvalidSubscribableTraitUsageError(observable))
on_lazy_set!(lazy::LazyObservable{D1}, ::ValidSubscribable{D2}, observable) where D1 where D2 = next!(lazy.inner, observable)

function on_subscribe!(observable::LazyObservable{D}, actor::A) where { A <: AbstractActor{D} } where D
    return subscribe!(observable.inner |> take(1) |> switchMap(D), actor)
end

lazy(T = Any) = LazyObservable{T}()
