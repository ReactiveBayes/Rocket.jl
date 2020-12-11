export OperatorTrait, TypedOperatorTrait, LeftTypedOperatorTrait, RightTypedOperatorTrait, InferableOperatorTrait, InvalidOperatorTrait
export AbstractOperator, TypedOperator, LeftTypedOperator, RightTypedOperator, InferableOperator
export as_operator, call_operator!, on_call!, operator_right
export OperatorsComposition, call_operator_composition!

export InvalidOperatorTraitUsageError, InconsistentSourceOperatorDataTypesError
export MissingOnCallImplementationError, MissingOperatorRightImplementationError

import Base: show, showerror
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
using Rocket

struct MyTypedOperator <: TypedOperator{Int, Int} end

function Rocket.on_call!(::Type{Int}, ::Type{Int}, op::MyTypedOperator, source)
    return proxy(Int, source, MyTypedOperatorProxy())
end

struct MyTypedOperatorProxy <: ActorProxy end

Rocket.actor_proxy!(::Type{Int}, ::MyTypedOperatorProxy, actor::A) where A = MyTypedOperatorProxiedActor{A}(actor)

struct MyTypedOperatorProxiedActor{A} <: Actor{Int}
    actor :: A
end

function Rocket.on_next!(actor::MyTypedOperatorProxiedActor, data::Int)
    # Do something with a data and/or redirect it to actor.actor
    next!(actor.actor, data + 1)
end

Rocket.on_error!(actor::MyTypedOperatorProxiedActor, err) = error!(actor.actor, err)
Rocket.on_complete!(actor::MyTypedOperatorProxiedActor)   = complete!(actor.actor)

source = from([ 0, 1, 2 ])
subscribe!(source |> MyTypedOperator(), logger())
;

# output

[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Data: 3
[LogActor] Completed
```

See also: [`OperatorTrait`](@ref), [`TypedOperator`](@ref), [`OperatorTrait`](@ref), [`ProxyObservable`](@ref), [`ActorProxy`](@ref), [`logger`](@ref)
"""
struct TypedOperatorTrait{L, R} <: OperatorTrait end

"""
Left typed operator trait specifies operator to be statically typed with input data type.
To infer output data type this object should specify a special function `operator_right(operator, ::Type{L}) where L` which will be
used to infer output data type. Left typed operator with input type `L` can only operate on input Observable with data type `L` and
will always produce an Observable with data type inferred from `operator_right(operator, ::Type{L})`.

# Examples

```jldoctest
using Rocket

struct CountIntegersOperator <: LeftTypedOperator{Int} end

function Rocket.on_call!(::Type{Int}, ::Type{Tuple{Int, Int}}, op::CountIntegersOperator, source)
    return proxy(Tuple{Int, Int}, source, CountIntegersOperatorProxy())
end

Rocket.operator_right(::CountIntegersOperator, ::Type{Int}) = Tuple{Int, Int}

struct CountIntegersOperatorProxy <: ActorProxy end

Rocket.actor_proxy!(::Type{Tuple{Int, Int}}, ::CountIntegersOperatorProxy, actor::A) where A = CountIntegersProxiedActor{A}(0, actor)

mutable struct CountIntegersProxiedActor{A} <: Actor{Int}
    current :: Int
    actor   :: A
end

function Rocket.on_next!(actor::CountIntegersProxiedActor, data::Int)
    current = actor.current
    actor.current += 1
    next!(actor.actor, (current, data)) # e.g.
end

Rocket.on_error!(actor::CountIntegersProxiedActor, err) = error!(actor.actor, err)
Rocket.on_complete!(actor::CountIntegersProxiedActor)   = complete!(actor.actor)

source = from([ 0, 0, 0 ])
subscribe!(source |> CountIntegersOperator(), logger())
;

# output

[LogActor] Data: (0, 0)
[LogActor] Data: (1, 0)
[LogActor] Data: (2, 0)
[LogActor] Completed
```

See also: [`OperatorTrait`](@ref), [`LeftTypedOperator`](@ref), [`operator_right`](@ref), [`OperatorTrait`](@ref), [`ProxyObservable`](@ref), [`ActorProxy`](@ref), [`enumerate`](@ref), [`logger`](@ref)
"""
struct LeftTypedOperatorTrait{L} <: OperatorTrait end

"""
Right typed operator trait specifies operator to be statically typed with output data type. It can operate on input Observable with any data type `L`
but will always produce an Observable with data type `R`.

# Examples

```jldoctest
using Rocket

struct ConvertToFloatOperator <: RightTypedOperator{Float64} end

function Rocket.on_call!(::Type{L}, ::Type{Float64}, op::ConvertToFloatOperator, source) where L
    return proxy(Float64, source, ConvertToFloatProxy{L}())
end

struct ConvertToFloatProxy{L} <: ActorProxy end

function Rocket.actor_proxy!(::Type{Float64}, proxy::ConvertToFloatProxy{L}, actor::A) where { L, A }
    return ConvertToFloatProxyActor{L, A}(actor)
end

struct ConvertToFloatProxyActor{L, A} <: Actor{L}
    actor :: A
end

function Rocket.on_next!(actor::ConvertToFloatProxyActor{L}, data::L) where L
    next!(actor.actor, convert(Float64, data)) # e.g.
end

Rocket.on_error!(actor::ConvertToFloatProxyActor, err) = error!(actor.actor, err)
Rocket.on_complete!(actor::ConvertToFloatProxyActor)   = complete!(actor.actor)

source = from([ 1, 2, 3 ])
subscribe!(source |> ConvertToFloatOperator(), logger())
;

# output

[LogActor] Data: 1.0
[LogActor] Data: 2.0
[LogActor] Data: 3.0
[LogActor] Completed
```

See also: [`OperatorTrait`](@ref), [`RightTypedOperator`](@ref), [`OperatorTrait`](@ref), [`ProxyObservable`](@ref), [`ActorProxy`](@ref), [`logger`](@ref)
"""
struct RightTypedOperatorTrait{R} <: OperatorTrait end

"""
Inferable operator trait specifies operator to be statically typed neither with input data type nor with output data type.
To infer output data type this object should specify a special function `operator_right(operator, ::Type{L}) where L` where `L` is input data type
which will be used to infer output data type.

```jldoctest
using Rocket

struct IdentityOperator <: InferableOperator end

function Rocket.on_call!(::Type{L}, ::Type{L}, op::IdentityOperator, source) where L
    return proxy(L, source, IdentityProxy())
end

struct IdentityProxy <: ActorProxy end

Rocket.operator_right(::IdentityOperator, ::Type{L}) where L = L

Rocket.actor_proxy!(::Type{L}, proxy::IdentityProxy, actor::A) where L where A = IdentityProxyActor{L, A}(actor)

struct IdentityProxyActor{L, A} <: Actor{L}
    actor :: A
end

function Rocket.on_next!(actor::IdentityProxyActor{L}, data::L) where L
    next!(actor.actor, data) # e.g.
end

Rocket.on_error!(actor::IdentityProxyActor, err) = error!(actor.actor, err)
Rocket.on_complete!(actor::IdentityProxyActor)   = complete!(actor.actor)

source = from([ 1, 2, 3 ])
subscribe!(source |> IdentityOperator(), logger())

source = from([ 1.0, 2.0, 3.0 ])
subscribe!(source |> IdentityOperator(), logger())
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

See also: [`OperatorTrait`](@ref), [`InferableOperator`](@ref), [`operator_right`](@ref), [`OperatorTrait`](@ref), [`ProxyObservable`](@ref), [`ActorProxy`](@ref), [`logger`](@ref)
"""
struct InferableOperatorTrait <: OperatorTrait end

"""
InvalidOperatorTrait trait specifies special 'invalid' behavior and types with such a trait specification cannot be used as an operator for an observable stream.
By default any type has InvalidOperatorTrait trait specification

See also: [`OperatorTrait`](@ref)
"""
struct InvalidOperatorTrait <: OperatorTrait end

"""
Supertype for all operators

See also: [`TypedOperator`](@ref), [`LeftTypedOperator`](@ref), [`RightTypedOperator`](@ref), [`InferableOperator`](@ref)
"""
abstract type AbstractOperator end

"""
Can be used as a supertype for any operator. Automatically specifies TypedOperatorTrait behavior.

# Examples
```jldoctest
using Rocket

struct MyOperator <: TypedOperator{Float64,String} end

as_operator(MyOperator)

# output
TypedOperatorTrait{Float64,String}()
```

See also: [`AbstractOperator`](@ref), [`TypedOperatorTrait`](@ref)
"""
abstract type TypedOperator{L, R} <: AbstractOperator end

"""
Can be used as a supertype for any operator. Automatically specifies LeftTypedOperatorTrait behavior.

# Examples
```jldoctest
using Rocket

struct MyOperator <: LeftTypedOperator{Float64} end

as_operator(MyOperator)

# output
LeftTypedOperatorTrait{Float64}()
```

See also: [`AbstractOperator`](@ref), [`LeftTypedOperatorTrait`](@ref), [`operator_right`](@ref)
"""
abstract type LeftTypedOperator{L}  <: AbstractOperator end

"""
Can be used as a supertype for any operator. Automatically specifies RightTypedOperatorTrait behavior.

# Examples
```jldoctest
using Rocket

struct MyOperator <: RightTypedOperator{Float64} end

as_operator(MyOperator)

# output
RightTypedOperatorTrait{Float64}()
```

See also: [`AbstractOperator`](@ref), [`RightTypedOperatorTrait`](@ref)
"""
abstract type RightTypedOperator{R} <: AbstractOperator end

"""
Can be used as a supertype for any operator. Automatically specifies InferableOperatorTrait behavior.

# Examples
```jldoctest
using Rocket

struct MyOperator <: InferableOperator end

as_operator(MyOperator)

# output
InferableOperatorTrait()
```

See also: [`AbstractOperator`](@ref), [`InferableOperatorTrait`](@ref), [`operator_right`](@ref)
"""
abstract type InferableOperator <: AbstractOperator end

"""
    as_operator(any)

This function checks operator trait behavior. May be used explicitly to specify operator trait behavior for any object.

See also: [`OperatorTrait`](@ref), [`AbstractOperator`](@ref)
"""
as_operator(::Type)                                            = InvalidOperatorTrait()
as_operator(::Type{ <: TypedOperator{L, R} })   where { L, R } = TypedOperatorTrait{L, R}()
as_operator(::Type{ <: LeftTypedOperator{L} })  where L        = LeftTypedOperatorTrait{L}()
as_operator(::Type{ <: RightTypedOperator{R} }) where R        = RightTypedOperatorTrait{R}()
as_operator(::Type{ <: InferableOperator })                    = InferableOperatorTrait()
as_operator(::O)                                where O        = as_operator(O)

call_operator!(operator::O, source::S) where { O, S } = check_call_operator!(as_operator(O), as_subscribable(S), operator, source)

call_operator!(operator::TypedOperator{L, R},        source::Subscribable{L}) where { L, R } = on_call!(L, R, operator, source)
call_operator!(operator::LeftTypedOperator{L},       source::Subscribable{L}) where { L    } = on_call!(L, operator_right(operator, L), operator, source)
call_operator!(operator::RightTypedOperatorTrait{R}, source::Subscribable{L}) where { L, R } = on_call!(L, R, operator, source)
call_operator!(operator::InferableOperator,          source::Subscribable{L}) where { L    } = on_call!(L, operator_right(operator, L), operator, source)

call_operator!(operator::TypedOperator{L, R},        source::ScheduledSubscribable{L}) where { L, R } = on_call!(L, R, operator, source)
call_operator!(operator::LeftTypedOperator{L},       source::ScheduledSubscribable{L}) where { L    } = on_call!(L, operator_right(operator, L), operator, source)
call_operator!(operator::RightTypedOperatorTrait{R}, source::ScheduledSubscribable{L}) where { L, R } = on_call!(L, R, operator, source)
call_operator!(operator::InferableOperator,          source::ScheduledSubscribable{L}) where { L    } = on_call!(L, operator_right(operator, L), operator, source)

check_call_operator!(::InvalidOperatorTrait, _,                          operator, source) = throw(InvalidOperatorTraitUsageError(operator))
check_call_operator!(::InvalidOperatorTrait, ::InvalidSubscribableTrait, operator, source) = throw(InvalidOperatorTraitUsageError(operator))
check_call_operator!(_,                      ::InvalidSubscribableTrait, operator, source) = throw(InvalidSubscribableTraitUsageError(source))

check_call_operator!(::TypedOperatorTrait{L},      ::SimpleSubscribableTrait{NotL}, operator, source) where { L, NotL } = throw(InconsistentSourceOperatorDataTypesError{L, NotL}(operator))
check_call_operator!(::LeftTypedOperatorTrait{L},  ::SimpleSubscribableTrait{NotL}, operator, source) where { L, NotL } = throw(InconsistentSourceOperatorDataTypesError{L, NotL}(operator))
check_call_operator!(::TypedOperatorTrait{L, R},   ::SimpleSubscribableTrait{L}, operator, source)    where { L, R }    = on_call!(L, R, operator, source)
check_call_operator!(::LeftTypedOperatorTrait{L},  ::SimpleSubscribableTrait{L}, operator, source)    where L           = on_call!(L, operator_right(operator, L), operator, source)
check_call_operator!(::RightTypedOperatorTrait{R}, ::SimpleSubscribableTrait{L}, operator, source)    where { L, R }    = on_call!(L, R, operator, source)
check_call_operator!(::InferableOperatorTrait,     ::SimpleSubscribableTrait{L},  operator, source)   where L           = on_call!(L, operator_right(operator, L), operator, source)

check_call_operator!(::TypedOperatorTrait{L},      ::ScheduledSubscribableTrait{NotL}, operator, source) where { L, NotL } = throw(InconsistentSourceOperatorDataTypesError{L, NotL}(operator))
check_call_operator!(::LeftTypedOperatorTrait{L},  ::ScheduledSubscribableTrait{NotL}, operator, source) where { L, NotL } = throw(InconsistentSourceOperatorDataTypesError{L, NotL}(operator))
check_call_operator!(::TypedOperatorTrait{L, R},   ::ScheduledSubscribableTrait{L}, operator, source)    where { L, R }    = on_call!(L, R, operator, source)
check_call_operator!(::LeftTypedOperatorTrait{L},  ::ScheduledSubscribableTrait{L}, operator, source)    where L           = on_call!(L, operator_right(operator, L), operator, source)
check_call_operator!(::RightTypedOperatorTrait{R}, ::ScheduledSubscribableTrait{L}, operator, source)    where { L, R }    = on_call!(L, R, operator, source)
check_call_operator!(::InferableOperatorTrait,     ::ScheduledSubscribableTrait{L},  operator, source)   where L           = on_call!(L, operator_right(operator, L), operator, source)


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
type of data of output Observable given the type of data of input Observable.

See also: [`AbstractOperator`](@ref), [`LeftTypedOperator`](@ref), [`InferableOperator`](@ref)
"""
operator_right(::TypedOperator{L, R},   ::Type{L}) where { L, R } = R
operator_right(::RightTypedOperator{R}, ::Type{L}) where { L, R } = R
operator_right(operator, _) = throw(MissingOperatorRightImplementationError(operator))

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

call_operator_composition!(composition::OperatorsComposition, source) = reduce(|>, composition.operators, init = source)

Base.:|>(source, composition::OperatorsComposition) = call_operator_composition!(composition, source)

# Backward compatibility
Base.:+(o1::AbstractOperator, o2::AbstractOperator)         = OperatorsComposition((o1, o2))
Base.:+(o1::AbstractOperator, c::OperatorsComposition)      = OperatorsComposition((o1, c.operators...))
Base.:+(c::OperatorsComposition, o2::AbstractOperator)      = OperatorsComposition((c.operators..., o2))
Base.:+(c1::OperatorsComposition, c2::OperatorsComposition) = OperatorsComposition((c1.operators..., c2.operators...))

Base.:|>(o1::AbstractOperator, o2::AbstractOperator)         = OperatorsComposition((o1, o2))
Base.:|>(o1::AbstractOperator, c::OperatorsComposition)      = OperatorsComposition((o1, c.operators...))
Base.:|>(c::OperatorsComposition, o2::AbstractOperator)      = OperatorsComposition((c.operators..., o2))
Base.:|>(c1::OperatorsComposition, c2::OperatorsComposition) = OperatorsComposition((c1.operators..., c2.operators...))

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

function Base.showerror(io::IO, err::InvalidOperatorTraitUsageError)
    print(io, "Type $(typeof(err.operator)) is not a valid operator type. \nConsider extending your type with one of the base Operator abstract types: TypedOperator, LeftTypedOperator, RightTypedOperator, InferableOperator or implement Rocket.as_operator(::Type{<:$(typeof(err.operator))}).")
end

"""
This error will be thrown if `|>` pipe operator is called with inconsistent data type

See also: [`on_call!`](@ref)
"""
struct InconsistentSourceOperatorDataTypesError{L, NotL}
    operator
end

function Base.showerror(io::IO, err::InconsistentSourceOperatorDataTypesError{L, NotL}) where L where NotL
    print(io, "Operator of type $(typeof(err.operator)) expects source data to be of type $(L), but $(NotL) found.")
end

"""
This error will be thrown if Julia cannot find specific method of `on_call!` function for a given operator.

See also: [`on_call!`](@ref)
"""
struct MissingOnCallImplementationError
    operator
end

function Base.showerror(io::IO, err::MissingOnCallImplementationError)
    print(io, "You probably forgot to implement on_call!(::Type, ::Type, operator::$(typeof(err.operator)), source).")
end

"""
This error will be thrown if Julia cannot find specific method of `operator_right` function for a given operator.

See also: [`operator_right`](@ref)
"""
struct MissingOperatorRightImplementationError
    operator
end

function Base.showerror(io::IO, err::MissingOperatorRightImplementationError)
    print(io, "You probably forgot to implement operator_right(operator::$(typeof(err.operator)), L).")
end
