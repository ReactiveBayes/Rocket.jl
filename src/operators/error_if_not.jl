export error_if_not

"""
    error_if_not(checkFn, errorFn) 

Creates an `error_if_not` operator, which performs a check for every emission on the source Observable with `checkFn`. 
If `checkFn` returns `false`, the operator sends an `error` event and unsubscribes from the observable.

Note: `error_if_not` is an alias for `error_if` operator with inverted `checkFn`.

# Arguments
- `checkFn`: check function with `(data) -> Bool` signature
- `errorFn`: error object generating function with `(data) -> Any` signature, optional

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream

# Examples
```jldoctest
using Rocket

source = from([1, 2, 3]) |> error_if_not((data) -> data < 2, (data) -> "CustomError")

subscription = subscribe!(source, lambda(
    on_next  = (d) -> println("Next: ", d),
    on_error = (e) -> println("Error: ", e),
    on_complete = () -> println("Completed")
));

# output
Next: 1
Error: CustomError
```

See also: [`error_if`](@ref), [`error_if_empty`](@ref), [`default_if_empty`](@ref), [`logger`](@ref)
"""
error_if_not(checkFn::F, errorFn::E = nothing) where { F, E } = error_if((d) -> !checkFn(d), errorFn)