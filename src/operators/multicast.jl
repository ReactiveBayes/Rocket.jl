export MulticastOperator, on_call!, operator_right
export MulticastWithFactoryOperator, on_call!, operator_right
export multicast, as_multicast

multicast(subject::S) where S = as_multicast(as_subject(S), subject)

as_multicast(::ValidSubject{D}, subject) where D = MulticastOperator(subject)
as_multicast(::InvalidSubject,  subject)         = throw(InvalidSubjectTraitUsageError(subject))

multicast(factory::F) where { F <: AbstractSubjectFactory } = MulticastWithFactoryOperator(factory)

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
