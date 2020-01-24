export ReplayOperator, on_call!, operator_right
export ReplayProxy, source_proxy!
export ReplayObservable, on_subscribe!
export ReplayActor, on_next!, on_error!, on_complete!, is_exhausted
export replay

import DataStructures: CircularBuffer

replay(count::Int) = ReplayOperator(count)

struct ReplayOperator <: InferableOperator
    count :: Int
end

function on_call!(::Type{L}, ::Type{L}, operator::ReplayOperator, source) where L
    return proxy(L, source, ReplayProxy{L}(operator.count))
end

operator_right(operator::ReplayOperator, ::Type{L}) where L = L

struct ReplayActor{L} <: NextActor{L}
    replay_observable
end

is_exhausted(actor::ReplayActor) = false

on_next!(actor::ReplayActor{L}, data::L) where L = push!(actor.replay_observable.cb, data)

struct ReplayProxy{L} <: SourceProxy
    count :: Int
end

source_proxy!(proxy::ReplayProxy{L}, source) where L = ReplayObservable{L}(proxy.count, source)

struct ReplayObservable{L} <: Subscribable{L}
    cb :: CircularBuffer{L}
    source

    ReplayObservable{L}(count::Int, source) where L = begin
        replay_observable = new(CircularBuffer{L}(count), source)
        replay_actor      = ReplayActor{L}(replay_observable)

        subscribe!(source, replay_actor)

        return replay_observable
    end
end

function on_subscribe!(observable::ReplayObservable, actor)
    for v in observable.cb
        next!(actor, v)
    end
    return subscribe!(observable.source, actor)
end
