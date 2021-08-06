export TeardownLogic, UnsubscribableTeardownLogic, CallableTeardownLogic, VoidTeardownLogic, InvalidTeardownLogic
export Teardown, as_teardown
export unsubscribe!, teardown!, on_unsubscribe!

export InvalidTeardownLogicTraitUsageError, InvalidMultipleTeardownLogicTraitUsageError, MissingOnUnsubscribeImplementationError

import Base: show

"""
Abstract type for all possible teardown logic traits.

See also: [`UnsubscribableTeardownLogic`](@ref), [`CallableTeardownLogic`](@ref), [`VoidTeardownLogic`](@ref), [`InvalidTeardownLogic`](@ref)
"""
abstract type TeardownLogic end

"""
Unsubscribable teardown logic trait behavior. Unsubscribable teardown object must define its own method
for `on_unsubscribe!()` function which will be invoked when actor decides to `unsubscribe!` from Observable.

See also: [`TeardownLogic`](@ref), [`on_unsubscribe!`](@ref), [`unsubscribe!`](@ref)
"""
struct UnsubscribableTeardownLogic <: TeardownLogic end

"""
Callable teardown logic trait behavior. Callable teardown object must be callable (insert meme with a surprised Pikachu here).

See also: [`TeardownLogic`](@ref), [`on_unsubscribe!`](@ref), [`unsubscribe!`](@ref)
"""
struct CallableTeardownLogic       <: TeardownLogic end

"""
Void teardown logic trait behavior. Void teardown object does nothing in `unsubscribe!` and may not define any additional methods.

See also: [`TeardownLogic`](@ref), [`on_unsubscribe!`](@ref), [`unsubscribe!`](@ref)
"""
struct VoidTeardownLogic           <: TeardownLogic end

"""
Default teardown logic trait behavour. Invalid teardwon object cannot be used in `unsubscribe!` function. Doing so will raise an error.

See also: [`TeardownLogic`](@ref), [`on_unsubscribe!`](@ref), [`unsubscribe!`](@ref)
"""
struct InvalidTeardownLogic        <: TeardownLogic end

"""
Abstract type for any teardown object. Each teardown object must be a subtype of `Teardown`.

See also: [`TeardownLogic`](@ref)
"""
abstract type Teardown end

"""
    as_teardown(::Type)

This function checks teardown trait behavior specification. Should be used explicitly to specify teardown logic trait behavior for any object.

# Examples

```jldoctest
using Rocket

struct MySubscription <: Teardown end

Rocket.as_teardown(::Type{<:MySubscription}) = UnsubscribableTeardownLogic()
Rocket.on_unsubscribe!(s::MySubscription)    = println("Unsubscribed!")

subscription = MySubscription()
unsubscribe!(subscription)
;

# output

Unsubscribed!
```

See also: [`Teardown`](@ref), [`TeardownLogic`](@ref)
"""
as_teardown(::Type)             = InvalidTeardownLogic()
as_teardown(::Type{<:Function}) = CallableTeardownLogic()

"""
    unsubscribe!(subscription)
    unsubscribe!(subscriptions::Tuple)
    unsubscribe!(subscriptions::AbstractVector)

`unsubscribe!` function is used to cancel Observable execution and to dispose any kind of resources used during an Observable execution.
If the input argument to the `unsubscribe!` function is either a tuple or a vector, it will first check that all of the arguments are valid subscription objects 
and if its true will unsubscribe from each of them individually. 

See also: [`Teardown`](@ref), [`TeardownLogic`](@ref), [`on_unsubscribe!`](@ref)
"""
unsubscribe!(teardown::T) where T = teardown!(as_teardown(T), teardown)

function unsubscribe!(subscriptions::Union{Tuple, AbstractVector})
    if !all(subscription -> subscription !== InvalidTeardownLogic(), as_teardown.(typeof.(subscriptions)))
        index = findnext(subscription -> as_teardown(typeof(subscription)) === InvalidTeardownLogic(), subscriptions, 1)
        throw(InvalidMultipleTeardownLogicTraitUsageError(index, subscriptions[index]))
    end
    foreach(subscriptions) do subscription
        try 
            unsubscribe!(subscription)
        catch error
            @error "Error occured during multiple unsubscription."
            @error error
        end
    end
    return nothing
end

teardown!(::UnsubscribableTeardownLogic, teardown) = on_unsubscribe!(teardown)
teardown!(::CallableTeardownLogic,       teardown) = teardown()
teardown!(::VoidTeardownLogic,           teardown) = begin end
teardown!(::InvalidTeardownLogic,        teardown) = throw(InvalidTeardownLogicTraitUsageError(teardown))

"""
    on_unsubscribe!(teardown)

Each valid teardown object with UnsubscribableTeardownLogic trait behavior must implement its own method
for `on_unsubscribe!()` function which will be invoked when actor decides to `unsubscribe!` from Observable.

See also: [`Teardown`](@ref), [`TeardownLogic`](@ref), [`UnsubscribableTeardownLogic`](@ref)
"""
on_unsubscribe!(teardown) = throw(MissingOnUnsubscribeImplementationError(teardown))
# -------------------------------- #
# Errors                           #
# -------------------------------- #

"""
This error will be thrown if `unsubscribe!` function is called with invalid teardown object.

See also: [`unsubscribe!`](@ref)
"""
struct InvalidTeardownLogicTraitUsageError
    teardown
end

function Base.show(io::IO, err::InvalidTeardownLogicTraitUsageError)
    print(io, "Type $(typeof(err.teardown)) has undefined teardown behavior. \nConsider implement as_teardown(::Type{<:$(typeof(err.teardown))}).")
end

"""
This error will be thrown if `unsubscribe!` function is called with a tuple with invalid teardown object in it.

See also: [`unsubscribe!`](@ref)
"""
struct InvalidMultipleTeardownLogicTraitUsageError 
    index
    teardown
end

function Base.show(io::IO, err::InvalidMultipleTeardownLogicTraitUsageError)
    print(io, "Check unsubscribe! argument list on index $((err.index)). Type $(typeof(err.teardown)) has undefined teardown behavior. \nConsider implement as_teardown(::Type{<:$(typeof(err.teardown))}).")
end

"""
This error will be thrown if Julia cannot find specific method of `on_unsubscribe!()` function for given teardown object.

See also: [`on_unsubscribe!`](@ref)
"""
struct MissingOnUnsubscribeImplementationError
    teardown
end

function Base.show(io::IO, err::MissingOnUnsubscribeImplementationError)
    print(io, "You probably forgot to implement on_unsubscribe!(unsubscribable::$(typeof(err.teardown))).")
end