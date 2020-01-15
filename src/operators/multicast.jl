
struct MulticastOperator <: InferableOperator
    subject
end

function on_call!(::Type{L}, ::Type{L}, operator::MulticastOperator, source) where L
    error("Not implemented")
end

operator_right(operator::MulticastOperator, ::Type{L}) where L = L
