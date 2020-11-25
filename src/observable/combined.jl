export combineLatest
export PushEach, PushEachBut, PushNew, PushNewBut, PushStrategy

import Base: show

"""
    combineLatest(sources...; strategy = PushEach())
    combineLatest(sources::S, strategy::G = PushEach()) where { S <: Tuple, U }

Combines multiple Observables to create an Observable whose values are calculated from the latest values of each of its input Observables.
Accept optinal update strategy object.

# Arguments
- `sources`: input sources
- `strategy`: optional update strategy for batching new values together

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

```
using Rocket

latest = combineLatest(of(1) |> async(0), from(2:5) |> async(0), strategy = PushNew())

subscribe!(latest, logger())
;

# output

[LogActor] Data: (1, 2)
[LogActor] Completed
```

See also: [`Subscribable`](@ref), [`subscribe!`](@ref), [`PushEach`](@ref), [`PushEachBut`](@ref), [`PushNew`](@ref), [`PushNewBut`](@ref), [`PushStrategy`](@ref)
"""
function combineLatest end

"""
    PushEach

`PushEach` update strategy specifies combineLatest operator to emit new value each time an inner observable emit a new value

See also: [`combineLatest`](@ref), [`PushEachBut`](@ref), [`PushNew`](@ref), [`PushNewBut`](@ref), [`PushStrategy`](@ref)
"""
struct PushEach end

"""
    PushEachBut{I}

`PushEachBut` update strategy specifies combineLatest operator to emit new value if and only if an inner observable with index `I` have a new value

See also: [`combineLatest`](@ref), [`PushEach`](@ref), [`PushNew`](@ref), [`PushNewBut`](@ref), [`PushStrategy`](@ref)
"""
struct PushEachBut{I} end

"""
    PushNew

`PushNew` update strategy specifies combineLatest operator to emit new value if and only if all inner observables have a new value

See also: [`combineLatest`](@ref), [`PushEach`](@ref), [`PushEachBut`](@ref), [`PushNewBut`](@ref), [`PushStrategy`](@ref)
"""
struct PushNew end

"""
    PushNewBut{I}

`PushNewBut{I}` update strategy specifies combineLatest operator to emit new value if and only if all inner observables except with index `I` have a new value

See also: [`combineLatest`](@ref), [`PushEach`](@ref), [`PushEachBut`](@ref), [`PushNew`](@ref), [`PushStrategy`](@ref)
"""
struct PushNewBut{I} end

"""
    PushStrategy(strategy::BitArray{1})

`PushStrategy` update strategy specifies combineLatest operator to emit new value if and only if all inner observables with index such that `strategy[index] = false` have a new value

See also: [`combineLatest`](@ref), [`PushEach`](@ref), [`PushEachBut`](@ref), [`PushNew`](@ref), [`PushNewBut`](@ref), [`collectLatest`](@ref)
"""
struct PushStrategy
    strategy :: BitArray{1}
end

combineLatest(; strategy = PushEach())                                       = error("combineLatest operator expects at least one inner observable on input")
combineLatest(args...; strategy = PushEach())                                = combineLatest(args, strategy)
combineLatest(sources::S, strategy::G = PushEach()) where { S <: Tuple, G }  = CombineLatestObservable{combined_type(sources), S, G}(sources, strategy)
combineLatest(sources::V, strategy::G = PushEach()) where { V <: Vector, G } = CombineLatestObservable{combined_type(sources), V, G}(sources, strategy)

##

struct CombineLatestInnerActor{L, W, I} <: Actor{L}
    wrapper :: W
end

Base.show(io::IO, inner::CombineLatestInnerActor{L, W, I}) where { L, W, I } = print(io, "CombineLatestInnerActor($L, $I)")

on_next!(actor::CombineLatestInnerActor{L, W, I}, data::L) where { L, W, I } = next_received!(actor.wrapper, data, Val{I}())
on_error!(actor::CombineLatestInnerActor{L, W, I}, err)    where { L, W, I } = error_received!(actor.wrapper, err, Val{I}())
on_complete!(actor::CombineLatestInnerActor{L, W, I})      where { L, W, I } = complete_received!(actor.wrapper, Val{I}())

##

struct CombineLatestActorWrapper{S, A, G}
    storage :: S
    actor   :: A

    nsize    :: Int
    strategy :: G           # Push update strategy
    cstatus  :: BitArray{1} # Completion status
    vstatus  :: BitArray{1} # Values status
    ustatus  :: BitArray{1} # Updates status

    subscriptions :: Vector{Teardown}

    CombineLatestActorWrapper{S, A, G}(storage::S, actor::A, strategy::G) where { S, A, G } = begin
        nsize   = length(storage)
        cstatus = falses(nsize)
        vstatus = falses(nsize)
        ustatus = falses(nsize)
        subscriptions = fill!(Vector{Teardown}(undef, nsize), voidTeardown)
        return new(storage, actor, nsize, strategy, cstatus, vstatus, ustatus, subscriptions)
    end
end

push_update!(wrapper::CombineLatestActorWrapper) = push_update!(wrapper.nsize, wrapper.vstatus, wrapper.cstatus, wrapper.strategy)

function push_update!(::Int, ::BitArray{1}, ::BitArray{1}, ::PushEach)
    return nothing
end

function push_update!(::Int, vstatus::BitArray{1}, ::BitArray{1}, ::PushEachBut{I}) where I
    @inbounds vstatus[I] = false
    return nothing
end

function push_update!(nsize::Int, vstatus::BitArray{1}, cstatus::BitArray, ::PushNew)
    unsafe_copyto!(vstatus, 1, cstatus, 1, nsize)
    return nothing
end

function push_update!(nsize::Int, vstatus::BitArray{1}, cstatus::BitArray, ::PushNewBut{I}) where I
    push_update!(nsize, vstatus, cstatus, PushNew())
    @inbounds vstatus[I] = true
    return nothing
end

function push_update!(nsize::Int, vstatus::BitArray{1}, cstatus::BitArray, strategy::PushStrategy)
    push_update!(nsize, vstatus, cstatus, PushNew())
    map!(|, vstatus, vstatus, strategy.strategy)
    return nothing
end

cstatus(wrapper::CombineLatestActorWrapper, index) = @inbounds wrapper.cstatus[index]
vstatus(wrapper::CombineLatestActorWrapper, index) = @inbounds wrapper.vstatus[index]
ustatus(wrapper::CombineLatestActorWrapper, index) = @inbounds wrapper.ustatus[index]

dispose(wrapper::CombineLatestActorWrapper) = begin fill!(wrapper.cstatus, true); foreach(s -> unsubscribe!(s), wrapper.subscriptions) end

function next_received!(wrapper::CombineLatestActorWrapper, data, index::Val{I}) where I
    setstorage!(wrapper.storage, data, index)
    @inbounds wrapper.vstatus[I] = true
    @inbounds wrapper.ustatus[I] = true
    if all(wrapper.vstatus) && !all(wrapper.cstatus)
        push_update!(wrapper)
        next!(wrapper.actor, snapshot(wrapper.storage))
    end
end

function error_received!(wrapper::CombineLatestActorWrapper, err, index::Val{I}) where I
    if !(@inbounds wrapper.cstatus[I])
        dispose(wrapper)
        error!(wrapper.actor, err)
    end
end

function complete_received!(wrapper::CombineLatestActorWrapper, ::Val{I}) where I
    if !all(wrapper.cstatus)
        @inbounds wrapper.cstatus[I] = true
        if ustatus(wrapper, I)
            @inbounds wrapper.vstatus[I] = true
        end
        if all(wrapper.cstatus) || (@inbounds wrapper.vstatus[I] === false)
            dispose(wrapper)
            complete!(wrapper.actor)
        end
    end
end

##

struct CombineLatestObservable{T, S, G} <: Subscribable{T}
    sources  :: S
    strategy :: G
end

function on_subscribe!(observable::CombineLatestObservable{T, S, G}, actor::A) where { T, S, G, A }
    storage = getmstorage(T)
    wrapper = CombineLatestActorWrapper{typeof(storage), A, G}(storage, actor, observable.strategy)

    for (index, source) in enumerate(observable.sources)
        @inbounds wrapper.subscriptions[index] = subscribe!(source, CombineLatestInnerActor{eltype(source), typeof(wrapper), index}(wrapper))
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
