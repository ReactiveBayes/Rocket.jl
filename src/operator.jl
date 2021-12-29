export OpType

import Base: eltype, |>, +

# TODO 2.0 - doc
abstract type Operator end

function on_call! end

function call_operator!(operator, source) 
    T = eltype(source)
    return on_call!(T, operator_eltype(operator, T), operator, source)
end

Base.:|>(source, operator::Operator) = call_operator!(operator, source)

"""
    operator_eltype(operator, L)

This function is used to infer type of data of output Observable given the type of data of input Observable.

See also: [`Operator`](@ref), [`FixedEltypeOperator`](@ref), [`InferredEltypeOperator`](@ref)
"""
function operator_eltype end

abstract type FixedEltypeOperator{R} <: Operator end

operator_eltype(::FixedEltypeOperator{R}, ::Type{L}) where { L, R } = R

# TODO - doc 2.0
struct OpType{T} end

OpType(::Type{T}) where T = OpType{T}()

# -------------------------------- #
# Operators composition            #
# -------------------------------- #

"""
    OperatorsComposition(operators)

OperatorsComposition is an object which helps to create a composition of multiple operators. To create a composition of two or more operators
overloaded `+` or `|>` can be used.

```jldoctest
using Rocket

composition = map(Int, (d) -> d ^ 2) + filter(d -> d % 2 == 0)

source = from(1:5) |> composition

subscribe!(source, logger())
;

# output

[LogActor] Data: 4
[LogActor] Data: 16
[LogActor] Completed
```

```jldoctest
using Rocket

composition = map(Int, (d) -> d ^ 2) |> filter(d -> d % 2 == 0)

source = from(1:5) |> composition

subscribe!(source, logger())
;

# output

[LogActor] Data: 4
[LogActor] Data: 16
[LogActor] Completed
```
"""
struct OperatorsComposition{O}
    operators :: O
end

call_operator_composition!(composition::OperatorsComposition, source) = foldl(|>, composition.operators, init = source)

Base.:|>(source, composition::OperatorsComposition) = call_operator_composition!(composition, source)

# Backward compatibility
Base.:+(o1::Operator, o2::Operator)                         = OperatorsComposition((o1, o2))
Base.:+(o1::Operator, c::OperatorsComposition)              = OperatorsComposition((o1, c.operators...))
Base.:+(c::OperatorsComposition, o2::Operator)              = OperatorsComposition((c.operators..., o2))
Base.:+(c1::OperatorsComposition, c2::OperatorsComposition) = OperatorsComposition((c1.operators..., c2.operators...))

Base.:|>(o1::Operator, o2::Operator)                         = OperatorsComposition((o1, o2))
Base.:|>(o1::Operator, c::OperatorsComposition)              = OperatorsComposition((o1, c.operators...))
Base.:|>(c::OperatorsComposition, o2::Operator)              = OperatorsComposition((c.operators..., o2))
Base.:|>(c1::OperatorsComposition, c2::OperatorsComposition) = OperatorsComposition((c1.operators..., c2.operators...))