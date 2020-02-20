export multicast

import Base: show

"""
    multicast(subject::S) where S
    multicast(factory::F) where { F <: AbstractSubjectFactory }

    The `multicast()`` operator takes a Subject and uses it to share the source execution. It returns what’s known as a `ConnectableObservable`,
    which has a connect() method. It has one simple job - subscribes to the source with the provided subject.

    # Example

    ```jldoctest
    using Rocket

    subject = make_subject(Int, mode = SYNCHRONOUS_SUBJECT_MODE)
    source  = from(1:5) |> multicast(subject)

    actor1 = logger("1")
    actor2 = logger("2")

    subscription1 = subscribe!(source, actor1)
    subscription2 = subscribe!(source, actor2)

    connect(source)

    unsubscribe!(subscription1)
    unsubscribe!(subscription2)
    ;

    # output

    [1] Data: 1
    [2] Data: 1
    [1] Data: 2
    [2] Data: 2
    [1] Data: 3
    [2] Data: 3
    [1] Data: 4
    [2] Data: 4
    [1] Data: 5
    [2] Data: 5
    [1] Completed
    [2] Completed
    ```

    See also: [`ConnectableObservable`](@ref), [`make_subject`](@ref), [`share`](@ref), [`publish`](@ref)
"""
multicast(subject::S) where S                               = as_multicast(as_subject(S), subject)
multicast(factory::F) where { F <: AbstractSubjectFactory } = MulticastWithFactoryOperator(factory)

as_multicast(::ValidSubject{D}, subject) where D = MulticastOperator(subject)
as_multicast(::InvalidSubject,  subject)         = throw(InvalidSubjectTraitUsageError(subject))

struct MulticastOperator <: InferableOperator
    subject
end

function on_call!(::Type{L}, ::Type{L}, operator::MulticastOperator, source) where L
    return connectable(operator.subject, source)
end

operator_right(operator::MulticastOperator, ::Type{L}) where L = L

struct MulticastWithFactoryOperator <: InferableOperator
    subject_factory
end

function on_call!(::Type{L}, ::Type{L}, operator::MulticastWithFactoryOperator, source) where L
    return connectable(create_subject(L, operator.subject_factory), source)
end

operator_right(operator::MulticastWithFactoryOperator, ::Type{L}) where L = L

Base.show(io::IO, operator::MulticastOperator)           = print(io, "MulticastOperator()")
Base.show(io::IO, factory::MulticastWithFactoryOperator) = print(io, "MulticastWithFactoryOperator()")
