export connectable, connect

import Base: show

"""
    ConnectableObservable{D}(subject, source)

A connectable observable encapsulates the multicasting infrastructure with provided subject, but does not immediately subscribe to the source.
It subscribes to the source when its `connect` method is called.

See also: [`connect`](@ref), [`Subscribable`](@ref)
"""
struct ConnectableObservable{D, J, S} <: Subscribable{D}
    subject :: J
    source  :: S
end

Base.show(io::IO, ::ConnectableObservable{D}) where D = print(io, "ConnectableObservable($D)")

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

See also: [`connect`](@ref), [`subscribe!`](@ref)
"""
connectable(subject, source) = as_connectable(eltype(subject), eltype(source), subject, source)

as_connectable(::Type{D1}, ::Type{D2}, subject, source)       where { D1, D2 }             = error("Element types $(D!) and $(D2) of subject and source observables should match.")
as_connectable(::Type{D1}, ::Type{D2}, subject::J, source::S) where { D1, D2 <: D1, J, S } = ConnectableObservable{D2, J, S}(subject, source)

"""
    connect(connectable::ConnectableObservable)

When `connect` is called, the subject passed to the multicast operator is subscribed to the source and the subject’s observers receive the multicast notifications.
Returns a subscription.

See also: [`connectable`](@ref), [`ConnectableObservable`](@ref)
"""
connect(connectable::ConnectableObservable) = subscribe!(connectable.source, connectable.subject)
