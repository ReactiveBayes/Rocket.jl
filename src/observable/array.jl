export ArrayObservable, on_subscribe!, from

import Base: ==

abstract type Scalarness end

struct Scalar              <: Scalarness end
struct NonScalar           <: Scalarness end
struct UndefinedScalarness <: Scalarness end

scalarness(::Type)                   = UndefinedScalarness()
scalarness(::Type{<:Number})         = Scalar()
scalarness(::Type{<:Char})           = Scalar()
scalarness(::Type{<:AbstractArray})  = NonScalar()
scalarness(::Type{<:Tuple})          = NonScalar()
scalarness(::Type{<:AbstractString}) = NonScalar()

as_array(x::T) where T = as_array(scalarness(T), x)

as_array(::Scalar, x)              = [ x ]
as_array(::NonScalar, x)           = collect(x)
as_array(::UndefinedScalarness, x) = error("Value of type $(typeof(x)) has undefined scalarness type. \nConsider implement scalarness(::Type{<:$(typeof(x))}).")

"""
    ArrayObservable{D}(values::Array{D, 1})

ArrayObservable wraps a regular Julia array into a synchronous observable

# Constructor arguments
- `values`: array of values to be wrapped

# See also: [`Subscribable`](@ref), [`from`](@ref)
"""
struct ArrayObservable{D} <: Subscribable{D}
    values::Array{D, 1}
end

function on_subscribe!(observable::ArrayObservable, actor)
    for value in observable.values
        next!(actor, value)
    end
    complete!(actor)
    return VoidTeardown()
end

"""
    from(x)

Creates an ArrayObservable that emits either a single value if x has a Scalar trait specification or a collection of values if x has a NonScalar trait specification.
Throws an ErrorException if x has UndefinedScalarness trait type. To specify scalarness for arbitrary type T some can implement an additional method
for `scalarness(::Type{<:MyType})` function and to specify scalarness behaviour.

# Examples

```jldoctest
using Rx

source = from([ 0, 1, 2 ])
subscribe!(source, LoggerActor{Int}())
;

# output

[LogActor] Data: 0
[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Completed

```

```jldoctest
using Rx

source = from(( 0, 1, 2 ))
subscribe!(source, LoggerActor{Int}())
;

# output

[LogActor] Data: 0
[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Completed

```

```jldoctest
using Rx

source = from(0)
subscribe!(source, LoggerActor{Int}())
;

# output

[LogActor] Data: 0
[LogActor] Completed

```

```jldoctest
using Rx

source = from("Hello, world!")
subscribe!(source, LoggerActor{Char}())
;

# output

[LogActor] Data: H
[LogActor] Data: e
[LogActor] Data: l
[LogActor] Data: l
[LogActor] Data: o
[LogActor] Data: ,
[LogActor] Data:
[LogActor] Data: w
[LogActor] Data: o
[LogActor] Data: r
[LogActor] Data: l
[LogActor] Data: d
[LogActor] Data: !
[LogActor] Completed

```

See also: [`ArrayObservable`](@ref)
"""
from(x)                      = from(as_array(x))
from(a::Array{D, 1}) where D = ArrayObservable{D}(a)

Base.:(==)(left::ArrayObservable{D},  right::ArrayObservable{D})  where D           = left.values == right.values
Base.:(==)(left::ArrayObservable{D1}, right::ArrayObservable{D2}) where D1 where D2 = false
