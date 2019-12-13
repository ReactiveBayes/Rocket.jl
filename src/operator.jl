import Base: |>

export OperatorTrait, ValidOperator, InvalidOperator
export Operator, as_operator, call_operator!
export |>

abstract type OperatorTrait{T, R} end

struct ValidOperator{T, R} <: OperatorTrait{T, R} end
struct InvalidOperator     <: OperatorTrait{Nothing, Nothing} end

abstract type Operator{T, R} end

as_operator(::Type)                                   = InvalidOperator()
as_operator(::Type{<:Operator{T, R}}) where T where R = ValidOperator{T, R}()

call_operator!(operator::T, source) where T = call_operator!(as_operator(T), operator, source)

function call_operator!(::InvalidOperator, operator, source)
    error("Type $(typeof(operator)) is not a valid operator type. Consider extending your type with base Operator{T, R} abstract type.")
end

function call_operator!(::ValidOperator{T, R}, operator, source::S) where { S <: Subscribable{L} } where L where T where R
    error("Operator of type $(typeof(operator)) expects source data to be of type $(T), but $(L) found.")
end

function call_operator!(::ValidOperator{T, R}, operator, source::S) where { S <: Subscribable{T} } where T where R
    on_call!(operator, source)
end

Base.:|>(source::S, operator) where { S <: Subscribable{T} } where T = call_operator!(operator, source)

on_call!(operator, source) = error("You probably forgot to implement on_call!(operator::$(typeof(operator)), source).")
