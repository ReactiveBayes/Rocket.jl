export zipped

import Base: show
import DataStructures: Deque

"""
    zipped(sources...)

Combines multiple Observables to create an Observable whose values are calculated from the values,
in order, of each of its input Observables.

# Arguments
- `sources`: input sources

# Examples
```jldoctest
using Rocket

source = zipped(of(1), from(2:5))

subscribe!(source, logger())
;

# output

[LogActor] Data: (1, 2)
[LogActor] Completed
```

```jldoctest
using Rocket

source = zipped(from(1:3), from(1:5))

subscribe!(source, logger())
;

# output

[LogActor] Data: (1, 1)
[LogActor] Data: (2, 2)
[LogActor] Data: (3, 3)
[LogActor] Completed
```

```jldoctest
using Rocket

source = zipped(completed(), of(0.0))

subscribe!(source, logger())
;

# output

[LogActor] Completed
```

See also: [`Subscribable`](@ref), [`subscribe!`](@ref)
"""
zipped()                                 = error("zipped operator expects at least one inner observable on input")
zipped(args...)                          = zipped(args)
zipped(sources::S) where { S <: Tuple }  = ZipObservable{combined_type(sources), S}(sources)
zipped(sources::V) where { V <: Vector } = ZipObservable{combined_type(sources), V}(sources)

##

struct ZipInnerActor{L, W, I} <: Actor{L}
    wrapper :: W
end

Base.show(io::IO, inner::ZipInnerActor{L, W, I}) where { L, W, I } = print(io, "ZipInnerActor($L, $I)")

on_next!(actor::ZipInnerActor{L, W, I}, data::L) where { L, W, I } = next_received!(actor.wrapper, data, Val{I}())
on_error!(actor::ZipInnerActor{L, W, I}, err)    where { L, W, I } = error_received!(actor.wrapper, err, Val{I}())
on_complete!(actor::ZipInnerActor{L, W, I})      where { L, W, I } = complete_received!(actor.wrapper, Val{I}())

##

struct ZipActorWrapper{S, A}
    actor  :: A
    values :: Deque{S}

    nsize   :: Int
    cstatus :: BitArray{1}
    vstatus :: Deque{BitArray{1}}

    subscriptions :: Vector{Teardown}

    ZipActorWrapper{S, A}(nsize::Int, actor::A) where { S, A } = begin
        values  = Deque{S}()
        cstatus = falses(nsize)
        vstatus = Deque{BitArray{1}}()

        push!(values, S())
        push!(vstatus, falses(nsize))

        subscriptions = fill!(Vector{Teardown}(undef, nsize), voidTeardown)
        return new(actor, values, nsize, cstatus, vstatus, subscriptions)
    end
end

cstatus(wrapper::ZipActorWrapper, index)       = wrapper.cstatus[index]
first_vstatus(wrapper::ZipActorWrapper, index) = first(wrapper.vstatus)[index]
last_vstatus(wrapper::ZipActorWrapper, index)  = last(wrapper.vstatus)[index]

dispose(wrapper::ZipActorWrapper) = begin fill!(wrapper.cstatus, true); foreach(s -> unsubscribe!(s), wrapper.subscriptions) end

function next_received!(wrapper::ZipActorWrapper{S}, data, index::Val{I}) where { S, I }
    cindex, cvstatus, cstorage = nothing, nothing, nothing # c - current

    for (counter, (vstatus, storage)) in enumerate(zip(wrapper.vstatus, wrapper.values))
        if vstatus[I] === false
            cindex   = counter
            cvstatus = vstatus
            cstorage = storage
            break
        end
    end

    if cindex === nothing || cvstatus === nothing || cstorage === nothing
        cindex   = length(wrapper.values) + 1
        cvstatus = falses(wrapper.nsize)
        cstorage = S()
        push!(wrapper.values, cstorage)
        push!(wrapper.vstatus, cvstatus)
    end

    setstorage!(cstorage, data, index)
    cvstatus[I] = true
    if cindex === 1 && all(cvstatus) && !all(wrapper.cstatus)
        next!(wrapper.actor, snapshot(cstorage))
        popfirst!(wrapper.values)
        popfirst!(wrapper.vstatus)

        if isempty(wrapper.values) || isempty(wrapper.vstatus)
            if any(wrapper.cstatus)
                dispose(wrapper)
                complete!(wrapper.actor)
            else
                push!(wrapper.values, S())
                push!(wrapper.vstatus, falses(wrapper.nsize))
            end
        end

    end
end

function error_received!(wrapper::ZipActorWrapper, err, index::Val{I}) where I
    if !wrapper.cstatus[I]
        dispose(wrapper)
        error!(wrapper.actor, err)
    end
end

function complete_received!(wrapper::ZipActorWrapper, ::Val{I}) where I
    if !all(wrapper.cstatus)
        wrapper.cstatus[I] = true
        if all(wrapper.cstatus) || first_vstatus(wrapper, I) === false
            dispose(wrapper)
            complete!(wrapper.actor)
        end
    end
end

##

##

struct ZipObservable{T, C} <: Subscribable{T}
    sources  :: C
end

function on_subscribe!(observable::ZipObservable{T, C}, actor::A) where { T, C, A }
    S       = typeof(getmstorage(T))
    nsize   = length(observable.sources)
    wrapper = ZipActorWrapper{S, A}(nsize, actor)

    for (index, source) in enumerate(observable.sources)
        wrapper.subscriptions[index] = subscribe!(source, ZipInnerActor{eltype(source), typeof(wrapper), index}(wrapper))
        if all(wrapper.cstatus) || (cstatus(wrapper, index) === true && first_vstatus(wrapper, index) === false)
            dispose(wrapper)
            break
        end
    end

    return ZipSubscription(wrapper)
end

##

struct ZipSubscription{W} <: Teardown
    wrapper :: W
end

as_teardown(::Type{ <: ZipSubscription }) = UnsubscribableTeardownLogic()

function on_unsubscribe!(subscription::ZipSubscription)
    dispose(subscription.wrapper)
    return nothing
end

Base.show(io::IO, ::ZipObservable{D}) where D = print(io, "ZipObservable($D)")
Base.show(io::IO, ::ZipSubscription)          = print(io, "ZipSubscription()")
