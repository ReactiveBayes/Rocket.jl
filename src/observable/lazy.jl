export LazyObservable, lazy, set!

import Base: |>
import Base: show

# TODO: Untested and undocumented

struct LazyObservable{D} <: Subscribable{D}
    inner :: PendingSubject{Any, SynchronousSubject{Any}}

    LazyObservable{D}() where D = new(make_pending_subject(Any; mode = Val(:sync)))
end

set!(lazy::LazyObservable{D}, observable::S) where D where S = on_lazy_set!(lazy, as_subscribable(S), observable)

on_lazy_set!(lazy::LazyObservable{D},  ::InvalidSubscribable,   observable) where D           = throw(InvalidSubscribableTraitUsageError(observable))
on_lazy_set!(lazy::LazyObservable{D1}, ::ValidSubscribable{D2}, observable) where D1 where D2 = next!(lazy.inner, observable)

function on_subscribe!(observable::LazyObservable{D}, actor) where D
    return subscribe!(observable.inner |> switch_map(D), actor)
end

lazy(T = Any) = LazyObservable{T}()

Base.show(io::IO, observable::LazyObservable{D}) where D = print(io, "LazyObservable($D)")
