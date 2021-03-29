export SubjectTrait
export ValidSubjectTrait, InvalidSubjectTrait, as_subject
export AbstractSubject, AbstractSubjectFactory, create_subject

export InvalidSubjectTraitUsageError, InconsistentSubjectDataTypesError

import Base: showerror, eltype

"""
Abstract type for all possible subject traits

See also: [`ValidSubjectTrait`](@ref), [`InvalidSubjectTrait`](@ref), [`as_subject`](@ref)
"""
abstract type SubjectTrait end

"""
Valid subject trait behavior

See also: [`SubjectTrait`](@ref)
"""
struct ValidSubjectTrait{D} <: SubjectTrait end

"""
Default subject trait behavior for all types.

See also: [`SubjectTrait`](@ref)
"""
struct InvalidSubjectTrait <: SubjectTrait end

"""
Supertype for Subject types. Automatically specifies `ValidSubject`, `SimpleSubscribableTrait` and `BaseActorTrait` traits.

See also: [`Subject`](@ref), [`ValidSubjectTrait`](@ref), [`SimpleSubscribableTrait`](@ref), [`BaseActorTrait`](@ref)
"""
abstract type AbstractSubject{D} end

"""
    as_subject(::Type)

This function checks subject trait behavior specification. Should be used explicitly to specify subject trait behavior for any object type.

See also: [`SubjectTrait`](@ref)
"""
as_subject(::Type)                                  = InvalidSubjectTrait()
as_subject(::Type{ <: AbstractSubject{D} }) where D = ValidSubjectTrait{D}()
as_subject(::O)                             where O = as_subject(O)

as_actor(::Type{ <: AbstractSubject{D} }) where D = BaseActorTrait{D}()

as_subscribable(::Type{ <: AbstractSubject{D} }) where D = SimpleSubscribableTrait{D}()

# Specialised methods for built-in default subject and actor types
@inline subscribe!(subject::AbstractSubject{T1}, actor::Actor{T2}) where { T2, T1 <: T2 } = on_subscribe!(subject, actor)
@inline subscribe!(subject::AbstractSubject{T},  actor::Actor{T})  where { T }            = on_subscribe!(subject, actor)

@inline subscribe!(subscribable::Subscribable{T1},          actor::AbstractSubject{T2}) where { T2, T1 <: T2 } = on_subscribe!(subscribable, actor)
@inline subscribe!(subscribable::ScheduledSubscribable{T1}, actor::AbstractSubject{T2}) where { T2, T1 <: T2 } = scheduled_subscription!(subscribable, actor, makeinstance(T1, getscheduler(subscribable)))

@inline subscribe!(subscribable::Subscribable{T},          actor::AbstractSubject{T}) where { T } = on_subscribe!(subscribable, actor)
@inline subscribe!(subscribable::ScheduledSubscribable{T}, actor::AbstractSubject{T}) where { T } = scheduled_subscription!(subscribable, actor, makeinstance(T, getscheduler(subscribable)))

Base.eltype(::AbstractSubject{D})            where D = D
Base.eltype(::Type{ <: AbstractSubject{D} }) where D = D

# -------------------------------- #
# Subject factory                  #
# -------------------------------- #

"""
Abstract type for all possible subject factories

See also: [`SubjectTrait`](@ref), [`ValidSubjectTrait`](@ref), [`InvalidSubjectTrait`](@ref)
"""
abstract type AbstractSubjectFactory end

"""
    create_subject(::Type{L}, factory::F) where L where { F <: AbstractSubjectFactory }

Actor creator function for a given factory `F`. Should be implemented explicitly for any `AbstractActorFactory` object

See also: [`AbstractSubjectFactory`](@ref), [`MissingCreateActorFactoryImplementationError`](@ref)
"""
function create_subject end

# -------------------------------- #
# Errors                           #
# -------------------------------- #

"""
    InvalidSubject usage error

See also: [`as_subject`](@ref)
"""
struct InvalidSubjectTraitUsageError <: Exception
    subject
end

function Base.showerror(io::IO, err::InvalidSubjectTraitUsageError)
    print(io, "Type $(typeof(err.subject)) is not a valid subject type. \nConsider implement as_subject(::Type{<:$(typeof(err.subject))}).")
end

"""
    InconsistentSubjectDataTypesError

See also: [`as_subject`](@ref)
"""
struct InconsistentSubjectDataTypesError{T1, T2} <: Exception
    subject
end

function Base.showerror(io::IO, err::InconsistentSubjectDataTypesError{T1, T2}) where T1 where T2
    # TODO: better error message
    print(io, "Subject of type $(typeof(err.subject)) operates on data of type $(T2), while context requires subject to operate on data of type $(T1).")
end
