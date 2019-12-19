export BehaviorSubject, as_subscribable, on_subscribe!
export on_next!, on_error!, on_complete!
export close

import Base: close

"""
    BehaviorSubject{D}

A variant of Subject that requires an initial value and emits its current value whenever it is subscribed to.

```
using Rx

b = BehaviorSubject{Int}(1)

subscription = subscribe!(b, LoggerActor{Int}())

next!(b, 2)

yield()

unsubscribe!(subscription)

next!(b, 3)

subscription = subscribe!(b, LoggerActor{Int}())
;

# output

[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Data: 3
```
"""
mutable struct BehaviorSubject{D} <: Actor{D}
    current :: D
    subject :: Subject{D}

    BehaviorSubject{D}(current::D) where D = new(current, Subject{D}())
end

as_subscribable(::Type{<:BehaviorSubject{D}}) where D = ValidSubscribable{D}()

function on_next!(subject::BehaviorSubject{D}, data::D) where D
    subject.current = data
    next!(subject.subject, data)
end

function on_error!(subject::BehaviorSubject, err)
    error!(subject.subject, err)
end

function on_complete!(subject::BehaviorSubject)
    complete!(subject.subject)
end

function on_subscribe!(subject::BehaviorSubject{D}, actor::A) where { A <: AbstractActor{D} } where D
    next!(actor, subject.current)
    return subscribe!(subject.subject, actor)
end

function close(subject::BehaviorSubject)
    close(subject.subject)
end
