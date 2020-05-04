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

subject = Subject(Int)
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

See also: [`ConnectableObservable`](@ref), [`Subject`](@ref), [`share`](@ref), [`publish`](@ref)
"""
multicast(subject::S) where S                               = as_multicast(as_subject(S), subject)
multicast(factory::F) where { F <: AbstractSubjectFactory } = MulticastWithFactoryOperator{F}(factory)

as_multicast(::ValidSubject{D}, subject::S) where { D, S } = MulticastOperator{S}(subject)
as_multicast(::InvalidSubject,  subject::S) where {    S } = throw(InvalidSubjectTraitUsageError(subject))

struct MulticastOperator{S} <: InferableOperator
    subject :: S
end

function on_call!(::Type{L}, ::Type{L}, operator::MulticastOperator, source) where L
    return connectable(operator.subject, source)
end

operator_right(operator::MulticastOperator, ::Type{L}) where L = L

struct MulticastWithFactoryOperator{F} <: InferableOperator
    subject_factory :: F
end

function on_call!(::Type{L}, ::Type{L}, operator::MulticastWithFactoryOperator, source) where L
    return connectable(create_subject(L, operator.subject_factory), source)
end

operator_right(operator::MulticastWithFactoryOperator, ::Type{L}) where L = L

Base.show(io::IO, ::MulticastOperator)            = print(io, "MulticastOperator()")
Base.show(io::IO, ::MulticastWithFactoryOperator) = print(io, "MulticastWithFactoryOperator()")
