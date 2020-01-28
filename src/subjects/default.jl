export make_subject, make_subject_factory
export ASYNCHRONOUS_SUBJECT_MODE, SYNCHRONOUS_SUBJECT_MODE
export DEFAULT_SUBJECT_MODE

# Default type for subject is an AsynchronousSubject
const ASYNCHRONOUS_SUBJECT_MODE = Val(:async)
const SYNCHRONOUS_SUBJECT_MODE  = Val(:sync)

const DEFAULT_SUBJECT_MODE = ASYNCHRONOUS_SUBJECT_MODE

function make_subject(::Type{T}; mode::Val{M} = DEFAULT_SUBJECT_MODE) where T where M
    if M === :async
        return AsynchronousSubject{T}()
    elseif M === :sync
        return SynchronousSubject{T}()
    end
    error("Invalid subject mode type $M in subject(::Type{T}; mode::Val{M}) function.")
end

function make_subject_factory(; mode::Val{M} = DEFAULT_SUBJECT_MODE) where M
    if M === :async
        return AsynchronousSubjectFactory()
    elseif M === :sync
        return SynchronousSubjectFactory()
    end
    error("Invalid subject mode type $M in subject_factory(; mode::Val{M}) function.")
end
