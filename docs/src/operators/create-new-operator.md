# Create a new operator from scratch

It is more complicated, but if you have to write an operator that cannot be made from a combination of existing operators, you can write an operator from scratch:

Each operator (e.g. `MyFancyOperator`) have to either be a subtype of one of abstract [`OperatorTrait`](@ref) trait types or define a

```julia
Rx.as_operator(::Type{<:MyFancyOperator}) = TypedOperatorTrait{T, R}()
# or
Rx.as_operator(::Type{<:MyFancyOperator}) = InferableOperatorTrait()
```

trait behavior.

In addition, operator must implement
```julia
Rx.on_call!(::Type{L}, ::Type{R}, operator::MyFancyOperator, source::S) where { S <: Subscribable{L} } where L

# or
# for inferable trait types you have to specify 'right' type with Rx.operator_right which should specify a type of data of produced Observable

Rx.on_call(::Type{L}, ::Type{R}, operator::MyFancyOperator, source::S) where { S <: Subscribable{L} } where L
Rx.operator_right(::MyFancyOperator, ::Type{L}) where L = R # where R should be an actual type, Int or even L itself e.g.

```

logic which has to return another Observable as a result of applying `MyFancyOperator` to a `source`.

!!! note
    It is not allowed to modify `source` Observable in any way. You have to return a new observable.

## Proxy observable

It might be useful to use [`ProxyObservable`](@ref) as a return result for an `on_call!` function.
ProxyObservable is a special Observable which proxying actors with the source and/or source with actors.

## Operators API

See more on operators in [API section](@ref operators_api)
