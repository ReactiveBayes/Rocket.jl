export debounce_time

import Base: close
import Base: show

# TODO: Work in progress
# TODO: Untested and undocumented

debounce_time(due_time::Int) = DebounceTimeOperator(due_time)

struct DebounceTimeOperator <: InferableOperator
    due_time :: Int
end

function on_call!(::Type{L}, ::Type{L}, operator::DebounceTimeOperator, source) where L
    return proxy(L, source, DebounceTimeProxy{L}(operator.due_time))
end

operator_right(operator::DebounceTimeOperator, ::Type{L}) where L = L

struct DebounceTimeProxy{L} <: ActorSourceProxy
    due_time :: Int
end

actor_proxy!(proxy::DebounceTimeProxy{L}, actor::A)   where { L, A } = DebounceTimeActor{L, A}(proxy.due_time, actor)
source_proxy!(proxy::DebounceTimeProxy{L}, source::S) where { L, S } = DebounceTimeObservable{L, S}(source)

struct DebounceTimeCompletionException <: Exception end
struct DebounceTimeCancellationException <: Exception end

mutable struct DebounceTimeActor{L, A} <: Actor{L}
    is_cancelled  :: Bool
    is_completed  :: Bool
    due_time      :: Int
    actor         :: A
    last_received :: Union{Nothing, L}
    condition     :: Condition

    DebounceTimeActor{L, A}(due_time::Int, actor::A) where { L, A } = begin
        self = new(false, false, due_time, actor, nothing, Condition())

        @async begin
            try
                if self.is_completed && !self.is_cancelled
                    complete!(self.actor)
                else
                    while !self.is_cancelled && !self.is_completed
                        wait(self.condition)
                        sleep(self.due_time / MILLISECONDS_IN_SECOND)
                        if !self.is_cancelled
                            next!(self.actor, self.last_received)
                            if self.is_completed
                                complete!(self.actor)
                            end
                        end
                    end
                end
            catch err
                if err isa DebounceTimeCompletionException
                    complete!(self.actor)
                elseif !(err isa DebounceTimeCancellationException)
                    error!(self.actor, err)
                end
            end
        end

        return self
    end
end

is_exhausted(actor::DebounceTimeActor) = actor.is_completed || actor.is_cancelled || is_exhausted(actor.actor)

function on_next!(actor::DebounceTimeActor{L}, data::L) where L
    actor.last_received = data
    notify(actor.condition)
end

function on_error!(actor::DebounceTimeActor, err)
    actor.is_cancelled = true
    actor.is_completed = true
    close(actor, DebounceTimeCancellationException())
    error!(actor.actor, err)
end

function on_complete!(actor::DebounceTimeActor)
    actor.is_completed = true
    close(actor)
end

Base.close(actor::DebounceTimeActor, excp = DebounceTimeCompletionException()) = notify(actor.condition, excp; error = true)

struct DebounceTimeObservable{L, S} <: Subscribable{L}
    source :: S
end

function on_subscribe!(observable::DebounceTimeObservable, actor::DebounceTimeActor)
    return DebounceTimeSubscription(actor, subscribe!(observable.source, actor))
end

struct DebounceTimeSubscription <: Teardown
    actor
    subscription
end

as_teardown(::Type{<:DebounceTimeSubscription}) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::DebounceTimeSubscription)
    if !subscription.actor.is_cancelled
        close(subscription.actor, DebounceTimeCancellationException())
    end
    subscription.actor.is_cancelled = true
    unsubscribe!(subscription.subscription)
    return nothing
end

Base.show(io::IO, operator::DebounceTimeOperator)                 = print(io, "DebounceTimeOperator()")
Base.show(io::IO, proxy::DebounceTimeProxy{L})            where L = print(io, "DebounceTimeProxy($L)")
Base.show(io::IO, actor::DebounceTimeActor{L})            where L = print(io, "DebounceTimeActor($L)")
Base.show(io::IO, observaable::DebounceTimeObservable{L}) where L = print(io, "DebounceTimeObservable($L)")
Base.show(io::IO, subscription::DebounceTimeSubscription)         = print(io, "DebounceTimeSubscription()")
