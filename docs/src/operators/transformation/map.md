# [Map Operator](@id operator_map)

```@docs
map
```

## Description

The map operator, similar to `map(f, array)`, applies a function to each value from the source. It's important to note that the function `f` is expected to be pure and without any side effects. The `map` operator is designed to create a copy of the original observable for each new subscriber. It independently executes the `f` function for each subscriber and doesn't share the resulting value. This might be inconvenient when `f` involves complex calculations or side effects.

```@example map-1
using Rocket

function f(x)
    println("Function `f` called") # Assume heavy calculations or side-effects
    return x + 1
end

subject = Subject(Int)

mapped = subject |> map(Int, f)

subscription1 = subscribe!(mapped, logger())
subscription2 = subscribe!(mapped, logger())

next!(subject, 1)

unsubscribe!(subscription1)
unsubscribe!(subscription2)
nothing #hide
```

In the example, you'll observe that "Function `f` called" is displayed twice. This happens because each subscriber receives their individual, distinct version of the modified data. To alter this behavior, one can utilize the `share()` operator. This operator creates only a single copy of the modified observable and shares the computed results.

```@example map-1
mapped_and_shared = mapped |> share()

subscription1 = subscribe!(mapped_and_shared, logger())
subscription2 = subscribe!(mapped_and_shared, logger())

next!(subject, 1)

unsubscribe!(subscription1)
unsubscribe!(subscription2)
nothing #hide
```

In this example, "Function `f` called" appears only once, and the computed value is shared between the two subscribers. Note, however, that this behaviour might be confusing in cases where the first subscribers completes the observable till its completion stage. For example:

```@example map-1
mapped_and_shared = from([ 0, 1, 2 ]) |> map(Int, f) |> share()

subscription1 = subscribe!(mapped_and_shared, logger())
subscription2 = subscribe!(mapped_and_shared, logger())

unsubscribe!(subscription1)
unsubscribe!(subscription2)
nothing #hide
```

In this scenario, the second subscriber doesn't receive any values because the first subscriber exhausts the single shared observable. Once the shared observable is used up, it doesn't produce any further values. This doesn't occur without the `share()` operator.

```@example map-1
mapped = from([ 0, 1, 2 ]) |> map(Int, f)

subscription1 = subscribe!(mapped, logger())
subscription2 = subscribe!(mapped, logger())

unsubscribe!(subscription1)
unsubscribe!(subscription2)
nothing #hide
```

## See also

[Operators](@ref what_are_operators)
