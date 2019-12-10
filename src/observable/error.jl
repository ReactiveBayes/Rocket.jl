export ErrorObservable, TypedErrorObservable, on_subscribe!, throwError

struct ErrorObservable{D} <: Subscribable{D}
    error
end

function on_subscribe!(observable::ErrorObservable{D}, actor::A) where { A <: AbstractActor{D} } where D
    error!(actor, observable.error)
end

throwError(error, T = Any) = ErrorObservable{T}(error)
