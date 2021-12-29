
export AbstractSubscription, unsubscribe!

import Base: show

abstract type AbstractSubscription end

"""
    unsubscribe!(subscription)
    unsubscribe!(subscriptions::Tuple)
    unsubscribe!(subscriptions::AbstractVector)

Cancels an associated observable execution and disposes any kind of resources used during the observable execution.
If the input argument to the `unsubscribe!` function is either a tuple or a vector, it will first check that all of the arguments are valid subscription objects 
and if its true will unsubscribe from each of them individually. 

See also: [`AbstractSubscription`](@ref)
"""
function unsubscribe! end

# TODO - 2.0
# function unsubscribe!(subscriptions::Union{Tuple, AbstractVector})
#     if !all(subscription -> subscription !== InvalidTeardownLogic(), as_teardown.(typeof.(subscriptions)))
#         index = findnext(subscription -> as_teardown(typeof(subscription)) === InvalidTeardownLogic(), subscriptions, 1)
#         throw(InvalidMultipleTeardownLogicTraitUsageError(index, subscriptions[index]))
#     end
#     foreach(subscriptions) do subscription
#         try 
#             unsubscribe!(subscription)
#         catch error
#             @error "Error occured during multiple unsubscription."
#             @error error
#         end
#     end
#     return nothing
# end

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