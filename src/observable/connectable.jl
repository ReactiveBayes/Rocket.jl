export ConnectableObservable, on_subscribe!
export connectable, as_connectable
export connect

struct ConnectableObservable{D} <: Subscribable{D}
    source
    subject
end

function on_subscribe!(observable::ConnectableObservable, actor)
    return subscribe!(observable.subject, actor)
end

connectable(subject::J, source::S) where J where S = as_connectable(as_subject(J), as_subscribable(S), subject, source)

as_connectable(::InvalidSubject,   ::InvalidSubscribable, subject, source)   = throw(InvalidSubjectTraitUsageError(subject))
as_connectable(::InvalidSubject,   as_subscribable,       subject, source)   = throw(InvalidSubjectTraitUsageError(subject))
as_connectable(as_subject,         ::InvalidSubscribable, subject, source)   = throw(InvalidSubscribableTraitUsageError(source))

as_connectable(::ValidSubject{D1}, ::ValidSubscribable{D2}, subject, source) where D1 where D2 = throw(InconsistentActorWithSubscribableDataTypesError(source, subject))
as_connectable(::ValidSubject{D},  ::ValidSubscribable{D},  subject, source) where D           = ConnectableObservable{D}(source, subject)

connect(connectable::ConnectableObservable) = subscribe!(connectable.source, connectable.subject)
