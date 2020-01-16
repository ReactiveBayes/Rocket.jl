export ReplaySubject, as_subscribable, on_subscribe!
export on_next!, on_error!, on_complete!, is_exhausted
export close

export ReplaySubjectFactory, create_subject

import DataStructures: CircularBuffer
import Base: close

"""
    ReplaySubject{D}(capacity)

A variant of Subject that "replays" or emits old values to new subscribers.
It buffers a set number of values and will emit those values immediately to any new subscribers
in addition to emitting new values to existing subscribers.

# Arguments
- `capacity`: how many values to replay

# Examples

```
using Rx

b = ReplaySubject{Int}(2)

subscription1 = subscribe!(b, LoggerActor{Int}("Actor 1"))

next!(b, 1)
next!(b, 2)

yield()

subscription2 = subscribe!(b, LoggerActor{Int}("Actor 2"))

next!(b, 3)
;

# Logs
# [Actor 1] Data: 1
# [Actor 1] Data: 2
# [Actor 2] Data: 1
# [Actor 2] Data: 2
# [Actor 1] Data: 3
# [Actor 2] Data: 3
```

See also: [`Subject`](@ref), [`BehaviorSubject`](@ref)
"""
struct ReplaySubject{D} <: Actor{D}
    cb      :: CircularBuffer{D}
    inner_subject

    ReplaySubject{D}(capacity::Int; inner_subject = Subject{D}()) where D = new(CircularBuffer{D}(capacity), inner_subject)
end

as_subject(::Type{<:ReplaySubject{D}})      where D = ValidSubject{D}()
as_subscribable(::Type{<:ReplaySubject{D}}) where D = ValidSubscribable{D}()

is_exhausted(actor::ReplaySubject) = is_exhausted(actor.inner_subject)

function on_next!(subject::ReplaySubject{D}, data::D) where D
    push!(subject.cb, data)
    next!(subject.inner_subject, data)
end

function on_error!(subject::ReplaySubject, err)
    error!(subject.inner_subject, err)
end

function on_complete!(subject::ReplaySubject)
    complete!(subject.inner_subject)
end

function on_subscribe!(subject::ReplaySubject, actor)
    for v in subject.cb
        next!(actor, v)
    end
    return subscribe!(subject.inner_subject, actor)
end

function close(subject::ReplaySubject)
    close(subject.inner_subject)
end

# ----------------------- #
# Replay Subject factory  #
# ----------------------- #

struct ReplaySubjectFactory <: AbstractSubjectFactory
    count :: Int
    inner_factory

    ReplaySubjectFactory(count::Int; inner_factory = SubjectFactory()) = new(count, inner_factory)
end

create_subject(::Type{L}, factory::ReplaySubjectFactory) where L = ReplaySubject{L}(factory.count, inner_subject = create_subject(L, factory.inner_factory))
