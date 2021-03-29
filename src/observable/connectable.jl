export ConnectableObservable, connectable, connect

import Base: ==
import Base: show

"""
    ConnectableObservable{D}(subject, source)

A connectable observable encapsulates the multicasting infrastructure with provided subject, but does not immediately subscribe to the source.
It subscribes to the source when its `connect` method is called.

See also: [`connect`](@ref), [`Subscribable`](@ref)
"""
@subscribable struct ConnectableObservable{D, J, S} <: Subscribable{D}
    subject :: J
    source  :: S
end

function on_subscribe!(observable::ConnectableObservable, actor)
    return subscribe!(observable.subject, actor)
end

"""
    connectable(subject::J, source::S) where J where S

Creates a `ConnectableObservable` with a given subject object and a source observable.

# Example

```jldoctest
using Rocket

c = connectable(Subject(Int; scheduler = AsapScheduler()), from(1:3))

subscribe!(c, logger());

connect(c);
;

# output

[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Data: 3
[LogActor] Completed

```

See also: [`ConnectableObservable`](@ref), [`connect`](@ref), [`subscribe!`](@ref)
"""
connectable(subject::J, source::S) where { J, S } = as_connectable(as_subject(J), as_subscribable(S), subject, source)

as_connectable(::InvalidSubjectTrait, ::InvalidSubscribableTrait, subject, source) = throw(InvalidSubjectTraitUsageError(subject))
as_connectable(::InvalidSubjectTrait, _,                          subject, source) = throw(InvalidSubjectTraitUsageError(subject))
as_connectable(_,                     ::InvalidSubscribableTrait, subject, source) = throw(InvalidSubscribableTraitUsageError(source))

as_connectable(::ValidSubjectTrait{D1}, ::SimpleSubscribableTrait{D2},    subject, source) where { D1, D2  } = throw(InconsistentActorWithSubscribableDataTypesError{D2, D1}(source, subject))
as_connectable(::ValidSubjectTrait{D1}, ::ScheduledSubscribableTrait{D2}, subject, source) where { D1, D2  } = throw(InconsistentActorWithSubscribableDataTypesError{D2, D1}(source, subject))

as_connectable(::ValidSubjectTrait{D1},  ::SimpleSubscribableTrait{D2},    subject::J, source::S) where { D1, D2 <: D1, J, S } = ConnectableObservable{D2, J, S}(subject, source)
as_connectable(::ValidSubjectTrait{D1},  ::ScheduledSubscribableTrait{D2}, subject::J, source::S) where { D1, D2 <: D1, J, S } = ConnectableObservable{D2, J, S}(subject, source)

"""
    connect(connectable::ConnectableObservable)

When `connect` is called, the subject passed to the multicast operator is subscribed to the source and the subject’s observers receive the multicast notifications,
which fits our basic mental model of stream multicasting. Returns a subscription.

See also: [`connectable`](@ref), [`ConnectableObservable`](@ref)
"""
connect(connectable::ConnectableObservable) = subscribe!(connectable.source, connectable.subject)

Base.:(==)(c1::ConnectableObservable{D},  c2::ConnectableObservable{D})  where { D      } = c1.subject == c2.subject && c1.source == c2.source
Base.:(==)(c1::ConnectableObservable{D1}, c2::ConnectableObservable{D2}) where { D1, D2 } = false

Base.show(io::IO, ::ConnectableObservable{D}) where D = print(io, "ConnectableObservable($D)")
