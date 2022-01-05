export PendingScheduler, release!

function release! end

import Base: show, similar

# mutable struct PendingActor{L, A} <: Actor{L}
#     actor :: A
#     last  :: Union{Nothing, L}
# end

# make_pending_actor(::Type{L}, actor::A) where { L, A } = PendingActor{L, A}(actor, nothing)

# getlast(actor::PendingActor)        = actor.last
# setlast!(actor::PendingActor, last) = actor.last = last

# function release!(actor::PendingActor, reset::Bool)
#     last = getlast(actor)
#     if last !== nothing
#         next!(actor.actor, getlast(actor))
#         if reset
#             setlast!(actor, nothing)
#         end
#     end
# end

# struct PendingScheduler <: AbstractScheduler 
#     reset   :: Bool
#     pending :: Vector{PendingActor}

#     PendingScheduler(reset::Bool = true) = new(reset, Vector{PendingActor}())
# end

# Base.show(io::IO, ::PendingScheduler) = print(io, "PendingScheduler()")

# Base.similar(::PendingScheduler) = PendingScheduler()

# makeinstance(_, scheduler::PendingScheduler) = scheduler

# instancetype(_, ::Type{ <: PendingScheduler }) = PendingScheduler

# release!(scheduler::PendingScheduler) = foreach((d) -> release!(d, scheduler.reset), scheduler.pending)

# function scheduled_next!(actor::PendingActor{L}, data::L, ::PendingScheduler) where L 
#     setlast!(actor, data)
#     return nothing
# end

# function scheduled_error!(actor::PendingActor, err, instance::PendingScheduler) 
#     release!(actor, instance.reset)
#     deregister!(instance, actor)
#     error!(actor.actor, err)
# end

# function scheduled_complete!(actor::PendingActor, instance::PendingScheduler) 
#     release!(actor, instance.reset)
#     deregister!(instance, actor)
#     complete!(actor.actor)
# end

# struct PendingSchedulerSubscription <: Teardown
#     subscription :: Teardown
#     scheduler    :: PendingScheduler
#     actor        :: PendingActor
# end

# as_teardown(::Type{ <: PendingSchedulerSubscription }) = UnsubscribableTeardownLogic()

# function on_unsubscribe!(subscription::PendingSchedulerSubscription)
#     unsubscribe!(subscription.subscription)
#     deregister!(subscription.scheduler, subscription.actor)
#     return nothing
# end

# function scheduled_subscription!(source::S, actor, instance::PendingScheduler) where S
#     pending = make_pending_actor(subscribable_extract_type(S), actor)
#     register!(instance, pending)
#     subscription = on_subscribe!(source, pending, instance)
#     return PendingSchedulerSubscription(subscription, instance, pending)
# end

# function register!(scheduler::PendingScheduler, actor::PendingActor) 
#     push!(scheduler.pending, actor)
# end

# function deregister!(scheduler::PendingScheduler, actor::PendingActor) 
#     filter!(a -> a !== actor, scheduler.pending)
# end

