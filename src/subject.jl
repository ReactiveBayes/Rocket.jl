export SubjectTrait
export ValidSubject, InvalidSubject, as_subject
export AbstractSubject, AbstractSubjectFactory, create_subject

export InvalidSubjectTraitUsageError, InconsistentSubjectDataTypesError

import Base: show

"""
Abstract type for all possible subject traits

See also: [`ValidSubject`](@ref), [`InvalidSubject`](@ref), [`as_subject`](@ref)
"""
abstract type SubjectTrait end

"""
Valid subject trait behavior

See also: [`SubjectTrait`](@ref)
"""
struct ValidSubject{D} <: SubjectTrait end

"""
Default subject trait behavior for all types.

See also: [`SubjectTrait`](@ref)
"""
struct InvalidSubject  <: SubjectTrait end

"""
Supertype for Subject types. Automatically specifies `ValidSubject`, `SimpleSubscribableTrait` and `BaseActorTrait` traits.

See also: [`Subject`](@ref), [`ValidSubject`](@ref), [`SimpleSubscribableTrait`](@ref), [`BaseActorTrait`](@ref)
"""
abstract type AbstractSubject{D} end

"""
    as_subject(::Type)

This function checks subject trait behavior specification. Should be used explicitly to specify subject trait behavior for any object type.

See also: [`SubjectTrait`](@ref)
"""
as_subject(::Type) = InvalidSubject()

as_subject(::Type{ <: AbstractSubject{D} })      where D = ValidSubject{D}()
as_actor(::Type{ <: AbstractSubject{D} })        where D = BaseActorTrait{D}()
as_subscribable(::Type{ <: AbstractSubject{D} }) where D = SimpleSubscribableTrait{D}()


# -------------------------------- #
# Subject factory                  #
# -------------------------------- #

"""
Abstract type for all possible subject factories

See also: [`SubjectTrait`](@ref), [`ValidSubject`](@ref), [`InvalidSubject`](@ref)
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

function Base.show(io::IO, err::InvalidSubjectTraitUsageError)
    print(io, "Type $(typeof(err.subject)) is not a valid subject type. \nConsider implement as_subject(::Type{<:$(typeof(err.subject))}).")
end

"""
    InconsistentSubjectDataTypesError

See also: [`as_subject`](@ref)
"""
struct InconsistentSubjectDataTypesError{T1, T2} <: Exception
    subject
end

function Base.show(io::IO, err::InconsistentSubjectDataTypesError{T1, T2}) where T1 where T2
    # TODO: better error message
    print(io, "Subject of type $(typeof(err.subject)) operates on data of type $(T2), while context requires subject to operate on data of type $(T1).")
end
