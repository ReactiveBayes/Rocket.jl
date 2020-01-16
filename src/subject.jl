export SubjectTrait
export ValidSubject, InvalidSubject, as_subject
export as_subscribable

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
    as_subject(::Type)

This function checks subject trait behavior specification. Should be used explicitly to specify subject trait behavior for any object type.

See also: [`SubjectTrait`](@ref)
"""
as_subject(::Type) = InvalidSubject()

as_subscribable(::Type{<:ValidSubject{D}}) where D = ValidSubscribable{D}()
