
abstract type OperatorTrait{T, R} end

struct ValidOperator{T, R} <: OperatorTrait{T, R} end
struct InvalidOperator     <: OperatorTrait{Nothing, Nothing} end

abstract type Operator{T, R} end

as_operator(::Type)                                   = InvalidOperator()
as_operator(::Type{<:Operator{T, R}}) where T where R = ValidOperator{T, R}()

call_operator!(operator::T, source) where T = call_operator!(as_operator(T), operator, source)

call_operator!(::InvalidOperator, operator, source) = error("Type $(typeof(operator)) is not a valid operator type. Consider extending your type with base Operator{T, R} abstract type.")
