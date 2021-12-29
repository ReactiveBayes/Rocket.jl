export subscribe!

import Base: show, showerror
import Base: eltype

abstract type Subscribable{T} end

Base.eltype(::Subscribable{T})            where T = T
Base.eltype(::Type{ <: Subscribable{T} }) where T = T

# TODO - do i need this?
union_type(::AbstractVector{ <: AbstractSubscribable{T} }) where T = T

"""
    subscribe!(subscribable, actor)   
    subscribe!(subscribable, factory::AbstractActorFactory) where { T, F <: AbstractActorFactory }
    subscribe!(subscriptions::Tuple)
    subscribe!(subscriptions::AbstractVector)

`subscribe!` function is used to attach an actor to subscribable. Must return an instance of `<: AbstractSubscription`.
If the input argument to the `subscribe!` function is an iterator of 2-argument iterable elements 
it subscribes to them sequentially and unsubscribes automatically in case of an error.
First element is considerend to be a subscribable, second argument is considered to be an actor.
Note, however, that vector-based version of `subscribe!` function might have poor performance in case of large inputs.

# Arguments
- `subscribable`: valid subscribable object
- `actor`: valid actor object

# Examples

```jldoctest
using Rocket

source = from((1, 2, 3))
subscribe!(source, logger())
;

# output

[LogActor] Data: 1
[LogActor] Data: 2
[LogActor] Data: 3
[LogActor] Completed
```

```jldoctest
using Rocket

source = from((1, 2, 3))
subscribe!(source, 1)
;

# output

ERROR: Type Int64 is not a valid actor type.
[...]
```

```jldoctest
using Rocket

source = from((1, 2, 3))
subscribe!(1, logger())
;

# output

ERROR: Type Int64 is not a valid subscribable type.
[...]
```

See also: [`next!`](@ref), [`error!`](@ref), [`complete!`]
"""
function subscribe! end

# Generic method that first fallbacks to a specific scheduler of `subscribable`
subscribe!(subscribable, any) = subscribe!(subscribable, any, getscheduler(subscribable))

# Method for an `AbstractActorFactory`
subscribe!(subscribable, factory::AbstractActorFactory, scheduler) = subscribe!(subscribable, create_actor(eltype(subscribable), factory), scheduler)

# TODO - 2.0
# Method for either tuple or a vector
# function subscribe!(args::Union{Tuple, AbstractVector})
#     # First check that all arguments are correct
#     foreach(enumerate(args)) do (index, arg)
#         if length(arg) === 2
#             source = first(arg)
#             actor  = last(arg)
#             if as_subscribable(typeof(source)) === InvalidSubscribableTrait()
#                 error("multiple_subscribe! usage: Invalid source '$(source)' found on index $(index)")
#             elseif !(typeof(actor) <: AbstractActorFactory) && !(typeof(actor) <: Function) && as_actor(typeof(actor)) === InvalidActorTrait()
#                 error("multiple_subscribe! usage: Invalid actor '$(actor)' found on index $(index)")
#             end
#         else
#             error("Invalid multiple_subscribe! usage: Individual argument should be a size-2 Tuple, found '$(arg)' on index $(index)")
#         end
#     end
#     return map(args) do arg
#         try 
#             return subscribe!(first(arg), last(arg))
#         catch error
#             @error "Error occured during multiple subscription. Return `voidTeardown` for '$arg' argument."
#             @error error
#             return voidTeardown
#         end
#     end
# end