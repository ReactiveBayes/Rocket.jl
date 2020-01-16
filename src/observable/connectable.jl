# TODO: WIP

struct ConnectableObservable{D} <: Subscribable{D}
    source
    subject
end

function on_subscribe!(observable::ConnectableObservable, actor)
    return subscribe!(observable.subject, actor)
end

connectable(subject, source::S) where S = as_connectable(as_subscribable(S), source)

as_connectable(::InvalidSubscribable, source)  = throw(InvalidSubscribableTraitUsageError(source))
as_connectable(::ValidSubscribable{D}, source) = ConnectableObservable{D}(source)

connect(connectable::ConnectableObservable) = subscribe!(connectable.source, connectable.subject)
