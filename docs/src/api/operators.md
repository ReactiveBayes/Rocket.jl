# [Operators API](@id operators_api)

## How to create a custom operator

If you need to write an operator that cannot be made from a combination of existing operators, then you can write a custom operator from scratch.

Each operator (e.g. `MyFancyOperator`) needs to either be (1) a subtype of one of abstract [`OperatorTrait`](@ref) trait types, or (2) define a

```julia
Rx.as_operator(::Type{<:MyFancyOperator}) = TypedOperatorTrait{T, R}()
# or
Rx.as_operator(::Type{<:MyFancyOperator}) = InferableOperatorTrait()
```

trait behavior.

In addition, an operator must implement a specific method for `on_call!` function with custom logic which has to return another Observable as a result of applying `MyFancyOperator` to a `source`.

```julia
Rx.on_call!(::Type{L}, ::Type{R}, operator::MyFancyOperator, source) where L = # some custom logic here

# or
# for inferable trait types you have to specify 'right' type with Rx.operator_right which should specify a type of data of produced Observable

Rx.on_call(::Type{L}, ::Type{R}, operator::MyFancyOperator, source) where L = # some custom logic here
Rx.operator_right(::MyFancyOperator, ::Type{L}) where L = R # where R should be an actual type, Int or even L itself e.g.

```

!!! note
    It is not allowed to modify the `source` Observable in any way; you have to return a new observable.

See more examples on custom operators in [Traits API section](@ref operators_api_traits)

!!! note
    It might be useful to return a [ProxyObservable](@ref observable_proxy) from an `on_call!` function.
    ProxyObservable is a special Observable which proxying actors with the source and/or source with actors.

## [Traits](@id operators_api_traits)

```@docs
OperatorTrait
as_operator
TypedOperatorTrait
LeftTypedOperatorTrait
RightTypedOperatorTrait
InferableOperatorTrait
InvalidOperatorTrait
```


## Types

```@docs
AbstractOperator
TypedOperator
LeftTypedOperator
RightTypedOperator
InferableOperator
on_call!
operator_right
OperatorsComposition
```

## Errors

```@docs
InvalidOperatorTraitUsageError
InconsistentSourceOperatorDataTypesError
MissingOnCallImplementationError
MissingOperatorRightImplementationError
```
