export OperatorTrait, TypedOperatorTrait, LeftTypedOperatorTrait, RightTypedOperatorTrait, InferableOperatorTrait, InvalidOperatorTrait
export AbstractOperator, TypedOperator, LeftTypedOperator, RightTypedOperator, InferableOperator
export as_operator, call_operator!, on_call!, operator_right
export OperatorsComposition, call_operator_composition!

export InvalidOperatorTraitUsageError, InconsistentSourceOperatorDataTypesError
export MissingOnCallImplementationError, MissingOperatorRightImplementationError

import Base: show
import Base: |>
import Base: +

"""
Abstract type for all possible operator traits

See also: [`TypedOperatorTrait`](@ref), [`LeftTypedOperatorTrait`](@ref), [`RightTypedOperatorTrait`](@ref), [`InferableOperatorTrait`](@ref), [`InvalidOperatorTrait`](@ref),
"""
abstract type OperatorTrait end

"""
Typed operator trait specifies operator to be statically typed with input and output data types.
Typed operator with input type `L` and output type `R` can only operate on input Observable with data type `L`
and will always produce an Observable with data type `R`.

# Examples

```jldoctest
using Rx

struct MyTypedOperator <: TypedOperator{Int, Int} end

function Rx.on_call!(::Type{Int}, ::Type{Int}, op::MyTypedOperator, s::S) where { S <: Subscribable{Int} }
    return proxy(Int, s, MyTypedOperatorProxy())
end

struct MyTypedOperatorProxy <: ActorProxy end

Rx.actor_proxy!(::MyTypedOperatorProxy, actor::A) where { A <: AbstractActor{Int} } = MyTypedOperatorProxiedActor{A}(actor)

struct MyTypedOperatorProxiedActor{ A <: AbstractActor{Int} } <: Actor{Int}
    actor :: A
end

function Rx.on_next!(actor::MyTypedOperatorProxiedActor{A}, data::Int) where { A <: AbstractActor{Int} }
    # Do something with a data and/or redirect it to actor.actor
    next!(actor.actor, data + 1)
end

Rx.on_error!(actor::MyTypedOperatorProxiedActor, err) = error!(actor.actor, err)
Rx.on_complete!(actor::MyTypedOperatorProxiedActor)   = complete!(actor.actor)

source = from([ 0, 1, 2 ])
subscribe!(source |> MyTypedOperator(), LoggerActor{Int}())
;

# output

[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Data: 3
[LogActor] Completed
```

See also: [`TypedOperator`](@ref), [`OperatorTrait`](@ref), [`ProxyObservable`](@ref), [`ActorProxy`](@ref)
"""
struct TypedOperatorTrait{L, R}   <: OperatorTrait end

"""
Left typed operator trait specifies operator to be statically typed with input data type.
To infer output data type this object should specify a special function `operator_right(operator, ::Type{L}) where L` which will be
used to infer output data type. Left typed operator with input type `L` can only operate on input Observable with data type `L` and
will always produce an Observable with data type `operator_right(operator, ::Type{L})`.

# Examples

```jldoctest
using Rx

struct CountIntegersOperator <: LeftTypedOperator{Int} end

function Rx.on_call!(::Type{Int}, ::Type{Tuple{Int, Int}}, op::CountIntegersOperator, s::S) where { S <: Subscribable{Int} }
    return proxy(Tuple{Int, Int}, s, CountIntegersOperatorProxy())
end

function Rx.operator_right(::CountIntegersOperator, ::Type{Int})
    return Tuple{Int, Int}
end

struct CountIntegersOperatorProxy <: ActorProxy end

function Rx.actor_proxy!(::CountIntegersOperatorProxy, actor::A) where { A <: AbstractActor{ Tuple{Int, Int} } }
    return CountIntegersProxiedActor{A}(0, actor)
end

mutable struct CountIntegersProxiedActor{ A <: AbstractActor{ Tuple{Int, Int} } } <: Actor{Int}
    current :: Int
    actor   :: A
end

function Rx.on_next!(actor::CountIntegersProxiedActor{A}, data::Int) where { A <: AbstractActor{ Tuple{Int, Int} } }
    current = actor.current
    actor.current += 1
    next!(actor.actor, (current, data)) # e.g.
end

Rx.on_error!(actor::CountIntegersProxiedActor, err) = error!(actor.actor, err)
Rx.on_complete!(actor::CountIntegersProxiedActor)   = complete!(actor.actor)

source = from([ 0, 0, 0 ])
subscribe!(source |> CountIntegersOperator(), LoggerActor{Tuple{Int, Int}}())
;

# output

[LogActor] Data: (0, 0)
[LogActor] Data: (1, 0)
[LogActor] Data: (2, 0)
[LogActor] Completed
```

See also: [`LeftTypedOperator`](@ref), [`operator_right`](@ref), [`OperatorTrait`](@ref), [`ProxyObservable`](@ref), [`ActorProxy`](@ref)
"""
struct LeftTypedOperatorTrait{L}  <: OperatorTrait end

"""
Right typed operator trait specifies operator to be statically typed with output data type.

# Examples

```jldoctest
using Rx

struct ConvertToFloatOperator <: RightTypedOperator{Float64} end

function Rx.on_call!(::Type{L}, ::Type{Float64}, op::ConvertToFloatOperator, s::S) where { S <: Subscribable{L} } where L
    return proxy(Float64, s, ConvertToFloatProxy{L}())
end

struct ConvertToFloatProxy{L} <: ActorProxy end

function Rx.actor_proxy!(proxy::ConvertToFloatProxy{L}, actor::A) where { A <: AbstractActor{Float64} } where L
    return ConvertToFloatProxyActor{L, A}(actor)
end

mutable struct ConvertToFloatProxyActor{ L, A <: AbstractActor{Float64} } <: Actor{L}
    actor :: A
end

function Rx.on_next!(actor::ConvertToFloatProxyActor{L, A}, data::L) where { A <: AbstractActor{Float64} } where L
    next!(actor.actor, convert(Float64, data)) # e.g.
end

Rx.on_error!(actor::ConvertToFloatProxyActor, err) = error!(actor.actor, err)
Rx.on_complete!(actor::ConvertToFloatProxyActor)   = complete!(actor.actor)

source = from([ 1, 2, 3 ])
subscribe!(source |> ConvertToFloatOperator(), LoggerActor{Float64}())
;

# output

[LogActor] Data: 1.0
[LogActor] Data: 2.0
[LogActor] Data: 3.0
[LogActor] Completed
```

See also: [`RightTypedOperator`](@ref), [`OperatorTrait`](@ref), [`ProxyObservable`](@ref), [`ActorProxy`](@ref)
"""
struct RightTypedOperatorTrait{R} <: OperatorTrait end

"""
Inferable operator trait specifies operator to be statically typed neither with input data type nor with output data type.
To infer output data type this object should specify a special function `operator_right(operator, ::Type{L}) where L` where `L` is input data type
which will be used to infer output data type.

```jldoctest
using Rx

struct IdentityOperator <: InferableOperator end

function Rx.on_call!(::Type{L}, ::Type{L}, op::IdentityOperator, s::S) where { S <: Subscribable{L} } where L
    return proxy(L, s, IdentityProxy{L}())
end

Rx.operator_right(::IdentityOperator, ::Type{L}) where L = L

struct IdentityProxy{L} <: ActorProxy end

function Rx.actor_proxy!(proxy::IdentityProxy{L}, actor::A) where { A <: AbstractActor{L} } where L
    return IdentityProxyActor{L, A}(actor)
end

mutable struct IdentityProxyActor{ L, A <: AbstractActor{L} } <: Actor{L}
    actor :: A
end

function Rx.on_next!(actor::IdentityProxyActor{L, A}, data::L) where { A <: AbstractActor{L} } where L
    next!(actor.actor, data) # e.g.
end

Rx.on_error!(actor::IdentityProxyActor, err) = error!(actor.actor, err)
Rx.on_complete!(actor::IdentityProxyActor)   = complete!(actor.actor)

source = from([ 1, 2, 3 ])
subscribe!(source |> IdentityOperator(), LoggerActor{Int}())

source = from([ 1.0, 2.0, 3.0 ])
subscribe!(source |> IdentityOperator(), LoggerActor{Float64}())
;

# output

[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Data: 3
[LogActor] Completed
[LogActor] Data: 1.0
[LogActor] Data: 2.0
[LogActor] Data: 3.0
[LogActor] Completed

```

See also: [`InferableOperator`](@ref), [`operator_right`](@ref), [`OperatorTrait`](@ref), [`ProxyObservable`](@ref), [`ActorProxy`](@ref)
"""
struct InferableOperatorTrait     <: OperatorTrait end

"""
InvalidOperatorTrait trait specifies special 'invalid' behavior and types with such a trait specification cannot be used as an operator for an observable stream.
By default any type has InvalidOperatorTrait trait specification
"""
struct InvalidOperatorTrait       <: OperatorTrait end

"""
Supertype for all operators
"""
abstract type AbstractOperator      end

"""
Can be used as a supertype for any operator. Automatically specifies TypedOperatorTrait behavior.

# Examples
```jldoctest
using Rx

struct MyOperator <: TypedOperator{Int, String} end

println(as_operator(MyOperator) === TypedOperatorTrait{Int, String}())
;

# output
true
```

See also: [`TypedOperatorTrait`](@ref)
"""
abstract type TypedOperator{L, R}   <: AbstractOperator end

"""
Can be used as a supertype for any operator. Automatically specifies LeftTypedOperatorTrait behavior.

# Examples
```jldoctest
using Rx

struct MyOperator <: LeftTypedOperator{Int} end

println(as_operator(MyOperator) === LeftTypedOperatorTrait{Int}())
;

# output
true
```

See also: [`LeftTypedOperatorTrait`](@ref), [`operator_right`](@ref)
"""
abstract type LeftTypedOperator{L}  <: AbstractOperator end

"""
Can be used as a supertype for any operator. Automatically specifies RightTypedOperatorTrait behavior.

# Examples
```jldoctest
using Rx

struct MyOperator <: RightTypedOperator{Int} end

println(as_operator(MyOperator) === RightTypedOperatorTrait{Int}())
;

# output
true
```

See also: [`RightTypedOperatorTrait`](@ref)
"""
abstract type RightTypedOperator{R} <: AbstractOperator end

"""
Can be used as a supertype for any operator. Automatically specifies InferableOperatorTrait behavior.

# Examples
```jldoctest
using Rx

struct MyOperator <: InferableOperator end

println(as_operator(MyOperator) === InferableOperatorTrait())
;

# output
true
```

See also: [`InferableOperatorTrait`](@ref), [`operator_right`](@ref)
"""
abstract type InferableOperator     <: AbstractOperator end

"""
    as_operator(::Type)

This function checks operator trait behavior. May be used explicitly to specify operator trait behavior for any object.

See also: [`OperatorTrait`](@ref), [`AbstractOperator`](@ref)
"""
as_operator(::Type)                                          = InvalidOperatorTrait()
as_operator(::Type{<:TypedOperator{L, R}})   where L where R = TypedOperatorTrait{L, R}()
as_operator(::Type{<:LeftTypedOperator{L}})  where L         = LeftTypedOperatorTrait{L}()
as_operator(::Type{<:RightTypedOperator{R}}) where R         = RightTypedOperatorTrait{R}()
as_operator(::Type{<:InferableOperator})                     = InferableOperatorTrait()

call_operator!(operator::T, source::S) where T where S = call_operator!(as_operator(T), as_subscribable(S), operator, source)

function call_operator!(as_operator, ::InvalidSubscribable, operator, source)
    throw(InvalidSubscribableTraitUsageError(source))
end

function call_operator!(::InvalidOperatorTrait, as_subscribable, operator, source)
    throw(InvalidOperatorTraitUsageError(operator))
end

function call_operator!(::TypedOperatorTrait{L, R}, ::ValidSubscribable{NotL}, operator, source) where L where R where NotL
    throw(InconsistentSourceOperatorDataTypesError{L, NotL}(operator))
end

function call_operator!(::TypedOperatorTrait{L, R}, ::ValidSubscribable{L}, operator, source) where L where R
    on_call!(L, R, operator, source)
end

function call_operator!(::LeftTypedOperatorTrait{L}, ::ValidSubscribable{NotL}, operator, source) where L where NotL
    throw(InconsistentSourceOperatorDataTypesError{L, NotL}(operator))
end

function call_operator!(::LeftTypedOperatorTrait{L}, ::ValidSubscribable{L}, operator, source) where L
    on_call!(L, operator_right(operator, L), operator, source)
end

function call_operator!(::RightTypedOperatorTrait{R}, ::ValidSubscribable{L}, operator, source) where L where R
    on_call!(L, R, operator, source)
end

function call_operator!(::InferableOperatorTrait, ::ValidSubscribable{L}, operator, source) where L
    on_call!(L, operator_right(operator, L), operator, source)
end

Base.:|>(source, operator::O) where { O <: AbstractOperator } = call_operator!(operator, source)

"""
    on_call!(::Type, ::Type, operator, source)

Each operator must implement its own method for `on_call!` function. This function is used to invoke operator on some Observable
and to produce another Observable with new logic (operator specific).

See also: [`AbstractOperator`](@ref)
"""
on_call!(::Type, ::Type, operator, source) = throw(MissingOnCallImplementationError(operator))

"""
    operator_right(operator, L)

Both LeftTypedOperator and InferableOperator must implement its own method for `operator_right` function. This function is used to infer
type of data of output Observable given type of data of input Observable.

See also: [`AbstractOperator`](@ref), [`LeftTypedOperator`](@ref), [`InferableOperator`](@ref)
"""
operator_right(operator::O, ::Type{L}) where { O <: TypedOperator{L, R}   } where L where R = R
operator_right(operator::O, ::Type{L}) where { O <: RightTypedOperator{R} } where L where R = R
operator_right(operator, L) = throw(MissingOperatorRightImplementationError(operator))

# -------------------------------- #
# Operators composition            #
# -------------------------------- #

struct OperatorsComposition
    operators
end

function call_operator_composition!(composition::OperatorsComposition, source)
    transformed = source
    for operator in composition.operators
        transformed = transformed |> operator
    end
    return transformed
end

Base.:|>(source, composition::C) where { C <: OperatorsComposition } = call_operator_composition!(composition, source)

Base.:+(o1::O1, o2::O2)                            where { O1 <: AbstractOperator } where { O2 <: AbstractOperator } = OperatorsComposition((o1, o2))
Base.:+(o1::O1, composition::OperatorsComposition) where { O1 <: AbstractOperator }                                  = OperatorsComposition((o1, composition.operators...))
Base.:+(composition::OperatorsComposition, o2::O2) where { O2 <: AbstractOperator }                                  = OperatorsComposition((composition.operators..., o2))

# -------------------------------- #
# Errors                           #
# -------------------------------- #

"""
This error will be thrown if `|>` pipe operator is called with invalid operator object

See also: [`on_call!`](@ref)
"""
struct InvalidOperatorTraitUsageError
    operator
end

function Base.show(io::IO, err::InvalidOperatorTraitUsageError)
    print(io, "Type $(typeof(err.operator)) is not a valid operator type. \nConsider extending your type with one of the base Operator abstract types: TypedOperator, LeftTypedOperator, RightTypedOperator, InferableOperator or implement Rx.as_operator(::Type{<:$(typeof(err.operator))}).")
end

"""
This error will be thrown if `|>` pipe operator is called with inconsistent data type

See also: [`on_call!`](@ref)
"""
struct InconsistentSourceOperatorDataTypesError{L, NotL}
    operator
end

function Base.show(io::IO, err::InconsistentSourceOperatorDataTypesError{L, NotL}) where L where NotL
    print(io, "Operator of type $(typeof(err.operator)) expects source data to be of type $(L), but $(NotL) found.")
end

"""
This error will be thrown if Julia cannot find specific method of `on_call!` function for a given operator.

See also: [`on_call!`](@ref)
"""
struct MissingOnCallImplementationError
    operator
end

function Base.show(io::IO, err::MissingOnCallImplementationError)
    print(io, "You probably forgot to implement on_call!(::Type, ::Type, operator::$(typeof(err.operator)), source).")
end

"""
This error will be thrown if Julia cannot find specific method of `operator_right` function for a given operator.

See also: [`operator_right`](@ref)
"""
struct MissingOperatorRightImplementationError
    operator
end

function Base.show(io::IO, err::MissingOperatorRightImplementationError)
    print(io, "You probably forgot to implement operator_right(operator::$(typeof(err.operator)), L).")
end
