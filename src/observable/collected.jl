export collectLatest

import Base: show

## TODO Undocumented and untested

collectLatest(::Type{T}, sources::S, ::Type{R} = Vector{T}, mappingFn::F = copy) where { T, S, R, F } = CollectLatestObservable{T, S, R, F}(sources, mappingFn)

## 

struct CollectLatestObservableWrapper{L, A, F}
    actor   :: A
    storage :: Vector{L}

    nsize    :: Int
    cstatus  :: BitArray{1} # Completion status
    vstatus  :: BitArray{1} # Values status

    subscriptions :: Vector{Teardown}

    mappingFn :: F

    CollectLatestObservableWrapper{L, A, F}(::Type{L}, actor::A, nsize::Int, mappingFn::F) where { L, A, F } = begin
        storage = Vector{L}(undef, nsize)
        cstatus = falses(nsize)
        vstatus = falses(nsize)
        subscriptions = fill!(Vector{Teardown}(undef, nsize), voidTeardown)
        return new(actor, storage, nsize, cstatus, vstatus, subscriptions, mappingFn)
    end
end

cstatus(wrapper::CollectLatestObservableWrapper, index) = @inbounds wrapper.cstatus[index]
vstatus(wrapper::CollectLatestObservableWrapper, index) = @inbounds wrapper.vstatus[index]

dispose(wrapper::CollectLatestObservableWrapper) = begin fill!(wrapper.cstatus, true); foreach(s -> unsubscribe!(s), wrapper.subscriptions) end

struct CollectLatestObservableInnerActor{L, W} <: Actor{L}
    index   :: Int
    wrapper :: W
end

Base.show(io::IO, ::CollectLatestObservableInnerActor{L}) where L = print(io, "CollectedObservableInnerActor($L)")

on_next!(actor::CollectLatestObservableInnerActor{L}, data::L) where L = next_received!(actor.wrapper, data, actor.index)
on_error!(actor::CollectLatestObservableInnerActor, err)               = error_received!(actor.wrapper, err, actor.index)
on_complete!(actor::CollectLatestObservableInnerActor)                 = complete_received!(actor.wrapper, actor.index)

function next_received!(wrapper::CollectLatestObservableWrapper, data, index::Int)
    @inbounds wrapper.storage[index] = data
    @inbounds wrapper.vstatus[index] = true
    if all(wrapper.vstatus) && !all(wrapper.cstatus)
        unsafe_copyto!(wrapper.vstatus, 1, wrapper.cstatus, 1, wrapper.nsize)
        next!(wrapper.actor, wrapper.mappingFn(wrapper.storage))
    end
end

function error_received!(wrapper::CollectLatestObservableWrapper, err, index::Int)
    if !(@inbounds wrapper.cstatus[index])
        dispose(wrapper)
        error!(wrapper.actor, err)
    end
end

function complete_received!(wrapper::CollectLatestObservableWrapper, index::Int)
    if !all(wrapper.cstatus)
        @inbounds wrapper.cstatus[index] = true
        if all(wrapper.cstatus) || (@inbounds wrapper.vstatus[index] === false)
            dispose(wrapper)
            complete!(wrapper.actor)
        end
    end
end

## 

struct CollectLatestObservable{T, S, R, F} <: Subscribable{ R }
    sources   :: S
    mappingFn :: F
end

function on_subscribe!(observable::CollectLatestObservable{L}, actor::A) where { L, A }
    sources = observable.sources
    wrapper = CollectLatestObservableWrapper{L, A, typeof(observable.mappingFn)}(L, actor, length(sources), observable.mappingFn)
    W       = typeof(wrapper)

    for (index, source) in enumerate(sources)
        @inbounds wrapper.subscriptions[index] = subscribe!(source, CollectLatestObservableInnerActor{L, W}(index, wrapper))
        if cstatus(wrapper, index) === true && vstatus(wrapper, index) === false
            dispose(wrapper)
            break
        end
    end

    if all(wrapper.cstatus)
        dispose(wrapper)
    end

    return CollectLatestSubscription(wrapper)
end

##

struct CollectLatestSubscription{W} <: Teardown
    wrapper :: W
end

as_teardown(::Type{ <: CollectLatestSubscription }) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::CollectLatestSubscription)
    dispose(subscription.wrapper)
    return nothing
end

Base.show(io::IO, ::CollectLatestObservable{D}) where D  = print(io, "CollectLatestObservable($D)")
Base.show(io::IO, ::CollectLatestSubscription)           = print(io, "CollectLatestSubscription()")