
export Subscription, unsubscribe!

import Base: show

abstract type Subscription end

"""
    unsubscribe!(subscription)
    unsubscribe!(subscriptions::Tuple)
    unsubscribe!(subscriptions::AbstractVector)

Cancels an associated observable execution and disposes any kind of resources used during the observable execution.
If the input argument to the `unsubscribe!` function is either a tuple or a vector, it will first check that all of the arguments are valid subscription objects 
and if its true will unsubscribe from each of them individually. 

See also: [`Subscription`](@ref)
"""
unsubscribe!(subscription) = unsubscribe!(getscheduler(subscription), subscription)



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