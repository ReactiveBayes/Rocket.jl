export delay

import Base: show

"""
    delay(delay::Int)

Creates a delay operators, which delays the emission of items from the source Observable
by a given timeout.

# Arguments:
- `delay::Int`: the delay duration in milliseconds (a number) until which the emission of the source items is delayed.

# Producing

Stream of type `<: Subscribable{L}` where `L` refers to type of source stream

See also: [`AbstractOperator`](@ref), [`InferableOperator`](@ref), [`ProxyObservable`](@ref)
"""
delay(delay::Int) = DelayOperator(delay)

struct DelayOperator <: InferableOperator
    delay :: Int
end

function on_call!(::Type{L}, ::Type{L}, operator::DelayOperator, source) where L
    return proxy(L, source, DelayProxy{L}(operator.delay))
end

operator_right(operator::DelayOperator, ::Type{L}) where L = L

struct DelayProxy{L} <: ActorSourceProxy
    delay :: Int
end

actor_proxy!(proxy::DelayProxy{L}, actor::A) where { L, A } = DelayActor{L, A}(proxy.delay, actor)
source_proxy!(proxy::DelayProxy{L}, source)  where L        = DelayObservable{L}(source)

struct DelayDataMessage{L}
    data :: L
end

struct DelayErrorMessage
    err
end

struct DelayCompleteMessage end

const DelayMessage{L} = Union{DelayDataMessage{L}, DelayErrorMessage, DelayCompleteMessage}

struct DelayQueueItem{L}
    message    :: DelayMessage{L}
    emmited_at :: Float64
end

mutable struct DelayActor{L, A} <: Actor{L}
    is_cancelled :: Bool
    delay        :: Int
    actor        :: A
    channel      :: Channel{DelayQueueItem{L}}

    DelayActor{L, A}(delay::Int, actor::A) where L where A = begin
        channel = Channel{DelayQueueItem{L}}(Inf)
        self    = new(false, delay, actor, channel)

        task = @async begin
            try
                while !self.is_cancelled
                    item = take!(channel)::DelayQueueItem{L}
                    sleepfor = (item.emmited_at + convert(Float64, self.delay / MILLISECONDS_IN_SECOND)) - time()
                    if sleepfor > 0.0
                        sleep(sleepfor)
                    end
                    if !self.is_cancelled
                        __process_delayed_message(self, item.message)
                    end
                end
            catch err
                __process_delayed_message(self, DelayErrorMessage(err))
            end
        end

        bind(channel, task)

        return self
    end
end

__process_delayed_message(actor::DelayActor{L}, message::DelayDataMessage{L}) where L = next!(actor.actor, message.data)
__process_delayed_message(actor::DelayActor,    message::DelayErrorMessage)           = error!(actor.actor, message.err)
__process_delayed_message(actor::DelayActor,    message::DelayCompleteMessage)        = complete!(actor.actor)

is_exhausted(actor::DelayActor) = is_exhausted(actor.actor)

on_next!(actor::DelayActor{L}, data::L) where L = push!(actor.channel, DelayQueueItem{L}(DelayDataMessage{L}(data), time()))
on_error!(actor::DelayActor{L}, err)    where L = push!(actor.channel, DelayQueueItem{L}(DelayErrorMessage(err), time()))
on_complete!(actor::DelayActor{L})      where L = push!(actor.channel, DelayQueueItem{L}(DelayCompleteMessage(), time()))

struct DelayObservable{L} <: Subscribable{L}
    source
end

function on_subscribe!(observable::DelayObservable, actor::DelayActor)
    return DelaySubscription(actor, subscribe!(observable.source, actor))
end

struct DelaySubscription <: Teardown
    actor
    subscription
end

as_teardown(::Type{<:DelaySubscription}) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::DelaySubscription)
    if !subscription.actor.is_cancelled
        close(subscription.actor.channel)
    end
    subscription.actor.is_cancelled = true
    unsubscribe!(subscription.subscription)
    return nothing
end

Base.show(io::IO, operator::DelayOperator)                 = print(io, "DelayOperator()")
Base.show(io::IO, proxy::DelayProxy{L})            where L = print(io, "DelayProxy($L)")
Base.show(io::IO, actor::DelayActor{L})            where L = print(io, "DelayActor($L)")
Base.show(io::IO, observaable::DelayObservable{L}) where L = print(io, "DelayObservable($L)")
Base.show(io::IO, subscription::DelaySubscription)         = print(io, "DelaySubscription()")
