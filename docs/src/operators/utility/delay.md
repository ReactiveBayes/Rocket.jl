# [Delay Operator](@id operator_delay)

```@docs
delay
```

## Description

Delays the emission of items from the source Observable by a given timeout

## Example

Delay every value with 1 second to the output

```julia
using Rocket
using Dates

source = from([ 1, 2, 3 ])
println(Dates.format(now(), "MM:SS"))
subscription = subscribe!(source |> delay(2000), lambda(
    on_next = (d) -> println("$(Dates.format(now(), "MM:SS")): $d")
));

# output

03:41
03:43: 1
03:43: 2
03:43: 3

```

## See also

[Operators](@ref what_are_operators)
