export ArrayObservable, from

import Base: ==
import Base: show

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
    ArrayObservable{D, H}(values::Vector{D}, scheduler::H) where { D, H }

ArrayObservable wraps a regular Julia array into an observable. Uses scheduler object to schedule messages delivery.

# Constructor arguments
- `values`: array of values to be wrapped
- `scheduler`: Scheduler-like object

See also: [`Subscribable`](@ref), [`from`](@ref)
"""
struct ArrayObservable{D, H} <: ScheduledSubscribable{D}
    values    :: Vector{D}
    scheduler :: H
end

getscheduler(observable::ArrayObservable) = observable.scheduler

function on_subscribe!(observable::ArrayObservable, actor, scheduler)
    for value in observable.values
        next!(actor, value, scheduler)
    end
    complete!(actor, scheduler)
    return voidTeardown
end

"""
    from(x; scheduler::H = AsapScheduler()) where { H <: AbstractScheduler }
    from(a::Vector{D}; scheduler::H = AsapScheduler()) where { D, H <: AbstractScheduler }

Creation operator for the `ArrayObservable` that emits either a single value if x has a `Scalar` trait specification or a collection of values if x has a `NonScalar` trait specification.
Throws an ErrorException if x has `UndefinedScalarness` trait type. To specify scalarness for arbitrary type T some can implement an additional method
for `scalarness(::Type{<:MyType})` function and to specify scalarness behavior. Optionally accepts custom scheduler-like object to schedule messages delivery.

# Arguments
- `x`: an object to be wrapped into array of values
- `scheduler`: optional, scheduler-like object

For an object `x` to be a valid input for a from operator it must implement
`Rocket.scalarness(::Type{ <: T })` method which should return either `Rocket.Scalar` or
`Rocket.NonScalar` objects. In first case `from` operator will treat `x` as a single scalar value and will wrap
it into a vector while in the second case `from` operator will convert `x` object into an array using `collect` function.

For arbitrary iterable objects consider using `iterable` creation operator.

# Note
`from` operators creates a copy of `x` using `collect` on a given object.

# Examples

```jldoctest
using Rocket

source = from([ 0, 1, 2 ])
subscribe!(source, logger())
;

# output

[LogActor] Data: 0
[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Completed

```

```jldoctest
using Rocket

source = from(( 0, 1, 2 ))
subscribe!(source, logger())
;

# output

[LogActor] Data: 0
[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Completed

```

```jldoctest
using Rocket

source = from(0)
subscribe!(source, logger())
;

# output

[LogActor] Data: 0
[LogActor] Completed

```

```jldoctest
using Rocket

source = from("Hello, world!")
subscribe!(source, logger())
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

See also: [`ArrayObservable`](@ref), [`subscribe!`](@ref), [`logger`](@ref), [`iterable`](@ref)
"""
from(x; scheduler::H = AsapScheduler()) where { H <: AbstractScheduler }               = from(as_array(x); scheduler = scheduler)
from(a::Vector{D}; scheduler::H = AsapScheduler()) where { D, H <: AbstractScheduler } = ArrayObservable{D, H}(copy(a), scheduler)

Base.:(==)(left::ArrayObservable{D, H},  right::ArrayObservable{D, H}) where { D, H } = left.values == right.values
Base.:(==)(left::ArrayObservable,        right::ArrayObservable)                      = false

Base.show(io::IO, ::ArrayObservable{D, H}) where { D, H } = print(io, "ArrayObservable($D, $H)")
