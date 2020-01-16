export SyncReplaySubject, as_subscribable, on_subscribe!
export on_next!, on_error!, on_complete!, is_exhausted
export close

export SyncReplaySubjectFactory, create_subject

import DataStructures: CircularBuffer

struct SyncReplaySubject{D} <: Actor{D}
    cb      :: CircularBuffer{D}
    subject :: SyncSubject{D}

    SyncReplaySubject{D}(capacity::Int) where D = new(CircularBuffer{D}(capacity), SyncSubject{D}())
end

as_subject(::Type{<:SyncReplaySubject{D}})      where D = ValidSubject{D}()
as_subscribable(::Type{<:SyncReplaySubject{D}}) where D = ValidSubscribable{D}()

is_exhausted(actor::SyncReplaySubject) = is_exhausted(actor.subject)

function on_next!(subject::ReplaySubject{D}, data::D) where D
    push!(subject.cb, data)
    next!(subject.subject, data)
end

function on_error!(subject::ReplaySubject, err)
    error!(subject.subject, err)
end

function on_complete!(subject::ReplaySubject)
    complete!(subject.subject)
end

function on_subscribe!(subject::ReplaySubject, actor)
    for v in subject.cb
        next!(actor, v)
    end
    return subscribe!(subject.subject, actor)
end

function close(subject::ReplaySubject)
    close(subject.subject)
end

# ----------------------- #
# Replay Subject factory  #
# ----------------------- #

struct ReplaySubjectFactory <: AbstractSubjectFactory
    count :: Int
end

create_subject(::Type{L}, factory::ReplaySubjectFactory) where L = ReplaySubject{L}(factory.count)
