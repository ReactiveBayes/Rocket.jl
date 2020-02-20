export ReplaySubject, ReplaySubjectFactory
export make_replay_subject, make_replay_subject_factory

import DataStructures: CircularBuffer

"""
    ReplaySubject{D, S}(capacity, subject)

A variant of Subject that "replays" or emits old values to new subscribers.
It buffers a set number of values and will emit those values immediately to any new subscribers
in addition to emitting new values to existing subscribers.

# Arguments
- `capacity`: how many values to replay
- `subject`: Subject base type

See also: [`make_replay_subject`](@ref), [`make_subject`](@ref)
"""
struct ReplaySubject{D, S} <: Actor{D}
    cb      :: CircularBuffer{D}
    subject :: S

    ReplaySubject{D, S}(count::Int, subject::S) where D where S = new(CircularBuffer{D}(count), subject)
end

as_subject(::Type{<:ReplaySubject{D}})      where D = ValidSubject{D}()
as_subscribable(::Type{<:ReplaySubject{D}}) where D = ValidSubscribable{D}()

is_exhausted(actor::ReplaySubject) = is_exhausted(actor.subject)

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

# --------------------------------- #
# Replay subject create operators #
# --------------------------------- #

make_replay_subject(::Type{T}, count::Int, subject_factory::F) where T where { F <: AbstractSubjectFactory } = make_replay_subject(T, count, create_subject(T, subject_factory))
make_replay_subject(::Type{T}, count::Int, subject::S)         where T where S                               = as_replay_subject(T, as_subject(S), count, subject)

as_replay_subject(::Type{T},  ::InvalidSubject,   count::Int, subject)    where T                   = throw(InvalidSubjectTraitUsageError(subject))
as_replay_subject(::Type{T1}, ::ValidSubject{T2}, count::Int, subject::S) where T1 where T2 where S = throw(InconsistentSubjectDataTypesError{T1, T2}(subject))
as_replay_subject(::Type{T},  ::ValidSubject{T},  count::Int, subject::S) where T where S           = ReplaySubject{T, S}(count, subject)

"""
    make_replay_subject(::Type{T}, count::Int; mode::Val{M} = DEFAULT_SUBJECT_MODE) where T where M

Creation operator for the `ReplaySubject`

See also: [`ReplaySubject`](@ref), [`make_subject`](@ref)
"""
make_replay_subject(::Type{T}, count::Int; mode::Val{M} = DEFAULT_SUBJECT_MODE) where T where M = make_replay_subject(T, count, make_subject_factory(mode = mode))

# ----------------------- #
# Replay subject factory  #
# ----------------------- #

struct ReplaySubjectFactory{M} <: AbstractSubjectFactory
    count :: Int
end

create_subject(::Type{L}, factory::ReplaySubjectFactory{M}) where L where M = make_replay_subject(L, factory.count; mode = Val(M))

make_replay_subject_factory(count::Int; mode::Val{M} = DEFAULT_SUBJECT_MODE) where M = ReplaySubjectFactory{M}(count)
