struct ConnectableObservable{D} <: Subscribable{D}
    observable
end

function on_subscribe!(observable::ConnectableObservable, actor)
    error("Not implemented")
end

connectable(source::S) where S = as_connectable(as_subscribable(S), source)

as_connectable(::InvalidSubscribable, source)  = throw(InvalidSubscribableTraitUsageError(source))
as_connectable(::ValidSubscribable{D}, source) = ConnectableObservable{D}(source)

connect(connectable::ConnectableObservable) = subscribe!(ConnectableObservable.observable)
