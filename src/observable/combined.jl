export combineLatest

import Base: show

"""
    combineLatest(sources...; batch = nothing)
    combineLatest(sources::Tuple, batch::U = nothing) where U

Combines multiple Observables to create an Observable whose values are calculated from the latest values of each of its input Observables.

# Arguments
- `sources`: input sources
- `batch`: optional update strategy for batching new values together

# Examples
```jldoctest
using Rocket

latest = combineLatest(of(1), from(2:5))

subscribe!(latest, logger())
;

# output

[LogActor] Data: (1, 2)
[LogActor] Data: (1, 3)
[LogActor] Data: (1, 4)
[LogActor] Data: (1, 5)
[LogActor] Completed
```

```jldoctest
using Rocket

latest = combineLatest(of(1), from(2:5)) |> map(Int, sum)

subscribe!(latest, logger())
;

# output

[LogActor] Data: 3
[LogActor] Data: 4
[LogActor] Data: 5
[LogActor] Data: 6
[LogActor] Completed
```

See also: [`Subscribable`](@ref), [`subscribe!`](@ref)
"""
combineLatest()                                             = error("combineLatest requires at least on observable on input")
combineLatest(args...; batch = nothing)                     = combineLatest(tuple(args...), batch)
combineLatest(sources::S, batch::U) where { S <: Tuple, U } = begin
    CombineLatestObservable{combined_type(sources), S, U}(sources, as_batch(batch))
end

as_batch(::Nothing)       = nothing
as_batch(batch::BitArray) = map(!, batch)

combined_type(sources) = Tuple{ map(source -> subscribable_extract_type(source), sources)... }

##

struct CombineLatestInnerActor{L, W, I} <: Actor{L}
    wrapper :: W
end

Base.show(io::IO, inner::CombineLatestInnerActor{L, W, I}) where { L, W, I } = print(io, "CombineLatestInnerActor($L, $I)")

on_next!(actor::CombineLatestInnerActor{L, W, I}, data::L) where { L, W, I } = next_received!(actor.wrapper, data, Val{I}())
on_error!(actor::CombineLatestInnerActor, err)                               = error_received!(actor.wrapper, err)
on_complete!(actor::CombineLatestInnerActor{L, W, I})      where { L, W, I } = complete_received!(actor.wrapper, Val{I}())

##

struct CombineLatestActorWrapper{S, A, U}
    storage :: S
    actor   :: A

    nsize   :: Int
    ustatus :: U           # Batched update status
    cstatus :: BitArray{1} # Completion status
    vstatus :: BitArray{1} # Values status

    subscriptions :: Vector{Teardown}

    CombineLatestActorWrapper{S, A, U}(storage::S, actor::A, ustatus::U) where { S, A, U } = begin
        nsize   = length(storage)
        vstatus = falses(nsize)
        cstatus = falses(nsize)
        subscriptions = fill!(Vector{Teardown}(undef, nsize), voidTeardown)
        return new(storage, actor, nsize, ustatus, cstatus, vstatus, subscriptions)
    end
end

isbatch(wrapper::CombineLatestActorWrapper{ <: Any, <: Any, <: BitArray}) = true
isbatch(wrapper::CombineLatestActorWrapper)                               = false

cstatus(wrapper::CombineLatestActorWrapper, index) = wrapper.cstatus[index]
vstatus(wrapper::CombineLatestActorWrapper, index) = wrapper.vstatus[index]

dispose(wrapper::CombineLatestActorWrapper) = begin fill!(wrapper.cstatus, true); foreach(s -> unsubscribe!(s), wrapper.subscriptions) end

function next_received!(wrapper::CombineLatestActorWrapper, data, index::Val{I}) where I
    setstorage!(wrapper.storage, data, index)
    wrapper.vstatus[I] = true
    if all(wrapper.vstatus) && !all(wrapper.cstatus)
        if isbatch(wrapper)
            unsafe_copyto!(wrapper.vstatus, 1, wrapper.cstatus, 1, wrapper.nsize)
            map!(|, wrapper.vstatus, wrapper.vstatus, wrapper.ustatus)
        end
        next!(wrapper.actor, snapshot(wrapper.storage))
    end
end

function error_received!(wrapper::CombineLatestActorWrapper, err)
    dispose(wrapper)
    error!(wrapper.actor, err)
end

function complete_received!(wrapper::CombineLatestActorWrapper, ::Val{I}) where I
    if !all(wrapper.cstatus)
        wrapper.cstatus[I] = true
        if all(wrapper.cstatus) || wrapper.vstatus[I] === false
            dispose(wrapper)
            complete!(wrapper.actor)
        end
    end
end

##

struct CombineLatestObservable{T, S, U} <: Subscribable{T}
    sources :: S
    ustatus :: U
end

function on_subscribe!(observable::CombineLatestObservable{T, S, U}, actor::A) where { T, S, U, A }
    storage = getmstorage(T)

    wrapper = CombineLatestActorWrapper{typeof(storage), A, U}(storage, actor, observable.ustatus)

    for (index, source) in enumerate(observable.sources)
        wrapper.subscriptions[index] = subscribe!(source, CombineLatestInnerActor{eltype(source), typeof(wrapper), index}(wrapper))
        if cstatus(wrapper, index) === true && vstatus(wrapper, index) === false
            dispose(wrapper)
            break
        end
    end

    if all(wrapper.cstatus)
        dispose(wrapper)
    end

    return CombineLatestSubscription(wrapper)
end

##

struct CombineLatestSubscription{W} <: Teardown
    wrapper :: W
end

as_teardown(::Type{ <: CombineLatestSubscription }) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::CombineLatestSubscription)
    dispose(subscription.wrapper)
    return nothing
end

Base.show(io::IO, ::CombineLatestObservable{D}) where D  = print(io, "CombineLatestObservable($D)")
Base.show(io::IO, ::CombineLatestSubscription)           = print(io, "CombineLatestSubscription()")

##
