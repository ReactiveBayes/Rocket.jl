import Base: |>

export OperatorTrait, TypedOperatorTrait, LeftTypedOperatorTrait, RightTypedOperatorTrait, InferableOperatorTrait, InvalidOperatorTrait
export AbstractOperator, TypedOperator, LeftTypedOperator, RightTypedOperator, InferableOperator
export as_operator, call_operator!, on_call!, operator_right
export |>

abstract type OperatorTrait end

struct TypedOperatorTrait{L, R}   <: OperatorTrait end
struct LeftTypedOperatorTrait{L}  <: OperatorTrait end
struct RightTypedOperatorTrait{R} <: OperatorTrait end
struct InferableOperatorTrait    <: OperatorTrait end
struct InvalidOperatorTrait       <: OperatorTrait end

abstract type AbstractOperator      end
abstract type TypedOperator{L, R}   <: AbstractOperator end
abstract type LeftTypedOperator{L}  <: AbstractOperator end
abstract type RightTypedOperator{R} <: AbstractOperator end
abstract type InferableOperator    <: AbstractOperator end

as_operator(::Type)                                          = InvalidOperatorTrait()
as_operator(::Type{<:TypedOperator{L, R}})   where L where R = TypedOperatorTrait{L, R}()
as_operator(::Type{<:LeftTypedOperator{L}})  where L         = LeftTypedOperatorTrait{L}()
as_operator(::Type{<:RightTypedOperator{R}}) where R         = RightTypedOperatorTrait{R}()
as_operator(::Type{<:InferableOperator})                     = InferableOperatorTrait()

call_operator!(operator::T, source) where T = call_operator!(as_operator(T), operator, source)

function call_operator!(::InvalidOperatorTrait, operator, source)
    error("Type $(typeof(operator)) is not a valid operator type. \nConsider extending your type with one of the base Operator abstract types: TypedOperator, LeftTypedOperator, RightTypedOperator, InferableOperator or implement Rx.as_operator(::Type{<:$(typeof(operator))}).")
end

function call_operator!(::TypedOperatorTrait{L, R}, operator, source::S) where { S <: Subscribable{NotL} } where L where R where NotL
    error("Operator of type $(typeof(operator)) expects source data to be of type $(L), but $(NotL) found.")
end

function call_operator!(::TypedOperatorTrait{L, R}, operator, source::S) where { S <: Subscribable{L} } where L where R
    on_call!(L, R, operator, source)
end

function call_operator!(::LeftTypedOperatorTrait{L}, operator, source::S) where { S <: Subscribable{NotL} } where L where NotL
    error("Operator of type $(typeof(operator)) expects source data to be of type $(L), but $(NotL) found.")
end

function call_operator!(::LeftTypedOperatorTrait{L}, operator, source::S) where { S <: Subscribable{L} } where L
    on_call!(L, operator_right(operator, L), operator, source)
end

function call_operator!(::RightTypedOperatorTrait{R}, operator, source::S) where { S <: Subscribable{L} } where L where R
    on_call!(L, R, operator, source)
end

function call_operator!(::InferableOperatorTrait, operator, source::S) where { S <: Subscribable{L} } where L
    on_call!(L, operator_right(operator, L), operator, source)
end

Base.:|>(source::S, operator) where { S <: Subscribable{T} } where T = call_operator!(operator, source)

on_call!(::Type, ::Type, operator, source) = error("You probably forgot to implement on_call!(::Type, ::Type, operator::$(typeof(operator)), source).")

operator_right(operator, L) = error("You probably forgot to implement operator_right(operator::$(typeof(operator)), L).")
