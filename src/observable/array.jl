export ArrayObservable, on_subscribe!, from

abstract type Scalarness end

struct Scalar              <: Scalarness end
struct NonScalar           <: Scalarness end
struct UndefinedScalarness <: Scalarness end

scalarness(::Type)                   = UndefinedScalarness()
scalarness(::Type{<:Number})         = Scalar()
scalarness(::Type{<:AbstractArray})  = NonScalar()
scalarness(::Type{<:Tuple})          = NonScalar()
scalarness(::Type{<:AbstractString}) = NonScalar()

as_array(x::T) where T = as_array(scalarness(T), x)

as_array(::Scalar, x)              = [ x ]
as_array(::NonScalar, x)           = collect(x)
as_array(::UndefinedScalarness, x) = error("Value of type $(typeof(x)) has undefined scalarness type. \nConsider implement scalarness(::Type{<:$(typeof(x))}).")

struct ArrayObservable{D} <: Subscribable{D}
    values::Array{D, 1}
end

function on_subscribe!(observable::ArrayObservable{D}, actor::A) where { A <: AbstractActor{D} } where D
    for value in observable.values
        next!(actor, value)
    end
    complete!(actor)
    return nothing
end

from(x)                      = from(as_array(x))
from(a::Array{D, 1}) where D = ArrayObservable{D}(a)
